# Global/Regional Web Front-End on Azure AKS

A production-grade template for running a containerised web front-end on AKS
with an active/active global edge, provisioned by Terraform 1.13 with
`hashicorp/azurerm` ~> 4.60 and shipped via GitHub Actions (OIDC, no
long-lived secrets).

This README captures not only **what** is being built but **why** —
the decisions, alternatives considered, and the trade-offs that led here.
The implementation plan it refers to lives at
`.claude/plans/indexed-spinning-rivest.md` (the source of truth for
execution detail).

---

## Goal

Deliver an Azure solution with:
- a **global** web front-end (edge L7),
- **regional** web front-ends running in containers on **AKS**,
- a **simple containerised website** to run on it,
- **GitHub Actions** that build an image, push to **ACR**, and deploy to AKS,
- HA/DR and resilience considered pragmatically, with cost kept in view,
- best-practice, latest-version infra (Terraform 1.13, azurerm 4.60+).

## Final architecture (at a glance)

- **Edge**: Azure Front Door **Premium** (WAF_Premium, managed + bot rules),
  anycast, health-probed routing across regions.
- **Regions**: **West Europe (weu)** + **North Europe (neu)**,
  **active/active**.
- **Ingress per region**: **Application Gateway for Containers (AGC)** —
  managed, data plane outside the cluster, Gateway API native. Installed via
  Terraform for the Azure resource, and the in-cluster ALB Controller +
  Gateway API CRDs via Helm in a post-apply job.
- **Compute**: AKS with zone-redundant node pools (zones `[1,2,3]`),
  Azure CNI Overlay + Cilium dataplane, Workload Identity, AKS-managed Entra
  + Azure RBAC.
- **Registry**: ACR **Premium** with geo-replication to weu + neu, public
  access disabled, Private Endpoints in each regional VNet.
- **App**: Node.js + Express (small, containerised, shows region/pod for
  observability), routed with Gateway API (`Gateway` + `HTTPRoute` +
  `HealthCheckPolicy`).
- **DNS/TLS**: default `*.azurefd.net` hostname for now; AFD-managed TLS.
  Custom domain trivially added later.
- **AFD → origin security**: AGC has no private frontend today, so the
  private-link-from-AFD pattern isn't available. Instead:
  1. AFD WAF custom rule asserting `X-Azure-FDID` matches our profile ID,
  2. NSG on the AGC subnet allowing inbound 443 only from the
     `AzureFrontDoor.Backend` service tag.

## Environments

- **`dev`** and **`prd`**, fully isolated (separate resource groups, separate
  state files, separate AFD / ACR / AKS instances).
- **Branch → env mapping**:
  - `dev` branch: PR plans `dev`; push/merge (or `workflow_dispatch`)
    **applies dev** and deploys to dev clusters.
  - `main` branch: PR plans `prd`; push/merge (or `workflow_dispatch`)
    **applies prd** and deploys to prd clusters (GitHub Environment `prd`
    has required reviewers).

## Naming convention

CAF-aligned, lower-kebab, env visible before region:

```
<type>-web-<env>-<region>[-<instance>]
```

- `env ∈ { dev, prd }`
- `region ∈ { weu, neu, global }`

| Type | Dev (WEU) | Prd (WEU) | Dev (global) | Prd (global) |
|---|---|---|---|---|
| Resource group | `rg-web-dev-weu` | `rg-web-prd-weu` | `rg-web-dev-global` | `rg-web-prd-global` |
| AKS cluster | `aks-web-dev-weu` | `aks-web-prd-weu` | — | — |
| AGC | `alb-web-dev-weu` | `alb-web-prd-weu` | — | — |
| ACR | — | — | `acrwebdevglobal<suffix>` | `acrwebprdglobal<suffix>` |
| AFD profile | — | — | `afd-web-dev` | `afd-web-prd` |

Every resource also carries common tags: `workload=web, env, region,
managed_by=terraform, repo=<owner>/<repo>`.

## Repository layout

```
repo/
├── app/                      # Node.js + Express sample site
├── deploy/chart/             # Helm chart (Deployment, Gateway, HTTPRoute, HPA, PDB, SA)
│   └── values-{dev,prd}-{weu,neu}.yaml
├── infra/                    # SINGLE Terraform root module
│   ├── backend.tf / providers.tf / main.tf / variables.tf / outputs.tf / locals.tf
│   ├── envs/
│   │   ├── dev.tfvars
│   │   ├── prd.tfvars
│   │   └── backends/{dev,prd}.hcl
│   ├── bootstrap/            # one-off state account + GitHub OIDC app reg
│   └── modules/
│       ├── network/ aks/ acr/ agc/ frontend-global/ observability/
│       └── regional/         # composition: network + aks + agc + regional observability
└── .github/workflows/
    ├── infra.yml             # plan on PR, apply on push to dev/main
    ├── app-build.yml         # build + push image to per-env ACR
    └── app-deploy.yml        # helm upgrade into the env's clusters
```

Terraform is driven purely from the root:

```sh
terraform -chdir=infra init  -backend-config=envs/backends/dev.hcl -reconfigure
terraform -chdir=infra plan  -var-file=envs/dev.tfvars -out=tfplan
terraform -chdir=infra apply tfplan
```

The `var.regions` map in `dev.tfvars` / `prd.tfvars` is iterated with
`for_each` over `module.region` — adding or removing a region is a tfvars
edit, not a code change. There are no per-region folders or duplicated
`main.tf` files.

## Decision history and context

This section records how we got here. None of it is speculative — each
decision is reflected in the plan and about to be reflected in the code.

### 1. Which topology?

Three options were weighed:

| | A | B | C |
|---|---|---|---|
| Global edge | AFD **Premium** + Private Link origins | AFD **Standard**, origin header-locked | AFD **Standard** |
| Regions | 2 × AKS, **active/active** | 2 × AKS, active + warm standby | 1 × AKS, 3 AZs |
| DR scope | Region | Region | AZ only |
| Rough £ | Highest | Middle | Lowest |

**Chosen: Option A.** Lowest RTO, strongest security posture, stronger WAF
(Premium managed + bot manager), room for caching static assets later.
Cost is justified for a production global site with a regional DR
requirement.

### 2. Which regions?

Considered UK South+UK West (in-country), UK South+North Europe
(cross-country), and West Europe + North Europe. **Chose West Europe +
North Europe** for full service parity and a widely used EU pair.

### 3. Which web framework?

Considered Go (tiny image, fastest cold-start), Node.js + Express, Python +
Flask, Next.js SSR. **Chose Node.js + Express** — small, well-known,
fast enough, and suits the team.

### 4. DNS and TLS?

Custom domain wasn't available yet, so: **use the default
`*.azurefd.net` hostname** with AFD-managed TLS. Custom domain + cert
is a small follow-up (swap the endpoint for a `Microsoft.Cdn/customdomains`
and add a DNS CNAME; TLS still AFD-managed).

### 5. Which ingress — and why *not* NGINX?

Originally planned `ingress-nginx` + Private Link Service from AFD
Premium. That was invalidated by 2026 reality:

- `kubernetes-sigs/ingress-nginx` was **retired March 2026** — no further
  releases, bug fixes, or CVE patches. Its announced successor *InGate*
  never matured and has also been dropped.
- The AKS **Application Routing** add-on (managed NGINX) has Microsoft
  extended support only until **November 2026** — too short a runway.
- **Application Gateway for Containers (AGC)** is Microsoft's strategic
  successor: Gateway API native, data plane **outside** the cluster (no
  ingress pods competing for node CPU/memory), managed by the
  `alb-controller` Helm chart in AKS.
- Trade-off: AGC does **not** currently expose a private frontend / PLS,
  so we can't use AFD Private Link origins. We compensate with a
  `X-Azure-FDID` WAF rule on AFD + `AzureFrontDoor.Backend` service-tag
  NSG on the AGC subnet. Only our own Front Door reaches the origins.

Other options considered: Envoy Gateway, Cilium Gateway API, Istio AKS
add-on, App Gateway v2 + AGIC. AGC won on Azure-native + managed data
plane; the security trade-off was accepted.

### 6. Dev / prod split and branch-based workflows

- `dev` branch drives dev; `main` drives prd.
- One root Terraform module; env differences live entirely in `dev.tfvars`
  / `prd.tfvars` and env-specific backend HCL (`envs/backends/<env>.hcl`).
- GitHub Environments `dev` and `prd` hold the OIDC federated credentials
  and (for `prd`) required reviewers.
- A single `terraform plan` / `terraform apply` per env — no per-region
  or per-stack apply jobs.

### 7. DRY Terraform layout

- Started with `envs/global` + per-region folders — rejected as duplication.
- Converged to: one `regional` composition module consumed with
  `for_each = var.regions`, and one root module that calls both the global
  resources and `module.region`. Adding a region is a tfvars edit.
- `main.tf`, `providers.tf`, `variables.tf`, `outputs.tf`, `backend.tf`,
  `locals.tf` live at the **root of `infra/`**. `envs/` contains only
  `dev.tfvars`, `prd.tfvars`, and `backends/*.hcl` — no `.tf` files.
- Cluster-side workloads (ALB Controller, Gateway API CRDs) are **not**
  installed by Terraform. They go in a post-apply `bootstrap-clusters`
  workflow job that reads `terraform output -json` and runs `helm upgrade`
  per cluster. This sidesteps the `for_each` + kubernetes/helm provider
  alias trap and cleanly separates Azure infra from Kubernetes workloads.

## Build / apply order

1. Run `infra/bootstrap` locally **twice** (once per env). Creates the
   state storage account and an Entra app reg per env with federated
   credentials for the matching GitHub Environment.
2. Protect `main`. Create `dev` off `main`.
3. Open a PR into `dev` → `infra.yml` plans dev, posts the plan.
4. Merge → `infra.yml` runs a single apply (global + both regions via
   `for_each`); `bootstrap-clusters` then installs Gateway API CRDs +
   alb-controller in each dev cluster.
5. Push to `dev` under `app/**` → `app-build.yml` pushes an image to the
   dev ACR → `app-deploy.yml` deploys to both dev clusters.
6. Promote with a PR from `dev` → `main`. `infra.yml` plans prd; merge
   (prd reviewer approves) → applies prd, runs `bootstrap-clusters`,
   deploys app.

## Verification (post-deploy)

- `terraform -chdir=infra plan -var-file=envs/<env>.tfvars` is a no-op on
  re-run.
- `kubectl -n web get pods,svc,gateway,httproute,healthcheckpolicy` shows
  `Accepted=True` / `Programmed=True`.
- `az network alb show` reports `provisioningState=Succeeded` per region;
  `az cdn frontdoor origin list` shows both AGC FQDNs enabled and probing
  healthy.
- `curl https://<endpoint>.z01.azurefd.net/` returns the page; reloads
  show the expected region/pod via the app's downward-API labels.
- Failover test: scale one region's Deployment to 0 → AFD shifts all
  traffic to the healthy region within the probe window (~2 min).
- WAF test: a benign OWASP payload is blocked with 403 and visible in
  `FrontDoorWebApplicationFirewallLog`.

## Cost sketch (baseline, pre-traffic)

Rough order-of-magnitude — confirm with the Azure pricing calculator for
your subscription/region:

- AFD Premium + WAF_Premium: ~$330/mo
- ACR Premium (geo-rep to 2 regions): ~$500/mo
- 2 × AGC: ~$50/mo + data processing
- AKS control plane (Standard tier SLA × 2): ~$150/mo
- Small node pools for dev, zone-redundant pools for prd
- Log Analytics ingestion + managed Prometheus: traffic-dependent

Dev can be trimmed hard (smaller node pools, shorter LA retention,
single-region if desired via a tfvars change).

## Related docs

- Plan (execution detail): `.claude/plans/indexed-spinning-rivest.md`
- Agent guidance: `AGENTS.md`
- Claude Code pointer: `CLAUDE.md`
