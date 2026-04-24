# AGENTS.md

Canonical instructions for any AI coding agent (Claude Code, Codex, Cursor,
etc.) working in this repository. Keep this file short and current — when
behaviour rules change, change this file.

## What this repo is

A Terraform + Kubernetes deployment of a containerised web front-end on
Azure AKS, fronted by Azure Front Door Premium across two regions
(active/active). See `README.md` for full context and decision history,
and `.claude/plans/indexed-spinning-rivest.md` for the execution plan.

The two `Az.ResourceGraph*` files at the repo root are unrelated Azure
PowerShell module artefacts left over from before this project started.
**Do not delete them and do not include them in commits unless the user
asks** — they are noise to ignore.

## Versions and tooling (non-negotiable)

- **Terraform**: `>= 1.13.0` (`required_version`).
- **Provider**: `hashicorp/azurerm ~> 4.60`. Also `hashicorp/azuread ~> 3.0`,
  `Azure/azapi ~> 2.0` for AGC / preview surface only when azurerm lacks
  the resource.
- **Helm**: `>= 3.15`. `kubectl` paired with `kubelogin`
  (`use-kubelogin: true` in workflows).
- **Node**: 22 LTS for the app.
- **GitHub Actions auth**: OIDC federated credentials only — no PATs, no
  service principal secrets.
- **Cloud**: Azure. Regions in use: `westeurope` (`weu`),
  `northeurope` (`neu`), plus a logical `global`.

## Layout you must preserve

```
infra/
├── *.tf                      # SINGLE root module at infra/ root
├── envs/
│   ├── dev.tfvars
│   ├── prd.tfvars
│   └── backends/{dev,prd}.hcl
├── bootstrap/                # state + OIDC, separate root module
└── modules/
    ├── network/ aks/ acr/ agc/ frontend-global/ observability/
    └── regional/             # composition module — used with for_each
```

Hard rules:

- **Do not create per-region or per-env folders under `infra/envs/`.** The
  only env-shaped files there are `dev.tfvars`, `prd.tfvars`, and
  `backends/{dev,prd}.hcl`. Anything else belongs at `infra/` root or in
  `infra/modules/`.
- **Do not duplicate `main.tf`.** Region differences are expressed as
  entries in the `var.regions` map, iterated with `for_each` over
  `module.region`.
- **Do not put `helm_release` or `kubernetes_*` resources in Terraform.**
  Cluster-side workloads (ALB Controller, Gateway API CRDs, the app)
  install via Helm in a post-apply workflow job. This is deliberate to
  avoid the `for_each` + provider-alias trap and to separate Azure infra
  from Kubernetes workloads.
- **Do not introduce `terraform_remote_state` between global and
  regional.** They live in one root module; Terraform's graph orders them
  correctly through module-output → module-input wiring.

## Naming and tagging

Pattern: `<type>-web-<env>-<region>[-<instance>]` (lower-kebab; env
before region). Globally unique types (ACR, KV, storage) drop hyphens
and append a short random suffix.

Always set `local.common_tags`:

```hcl
locals {
  common_tags = {
    workload   = "web"
    env        = var.env
    region     = var.region   # or "global"
    managed_by = "terraform"
    repo       = "<owner>/<repo>"
  }
}
```

Every resource that supports `tags` must receive `local.common_tags`.

## Branch and workflow rules

- `dev` branch → dev env. `main` branch → prd env. PRs into either branch
  trigger `terraform plan` against the matching env. Merges (or
  `workflow_dispatch`) trigger `apply`.
- `main` is protected. Apply against prd is gated by the GitHub
  Environment `prd` (required reviewers).
- All workflows derive `env` from the trigger; never hardcode `dev` or
  `prd` in step inputs.
- Workflows use `azure/login@v2` with OIDC. No `creds:` blocks, no
  `AZURE_CREDENTIALS` secret.

## Coding conventions

### Terraform

- One resource per logical concept; group with comments, not files.
- Inputs validated with `validation {}` blocks where it pays for itself
  (region keys, SKU choices, CIDR shape). Don't validate things Azure
  will already reject.
- Outputs: prefer maps keyed by `region_key` for anything multi-region so
  workflows can iterate.
- Pin module sources with relative paths (`./modules/...`); do not vendor
  third-party modules without discussion.
- `terraform fmt` and `terraform validate` must pass before commit. CI
  enforces this.

### Kubernetes / Helm

- Gateway API only — no `Ingress` resources.
- Gateway uses `gatewayClassName: azure-alb-external`. The Service is
  ClusterIP. AGC handles external exposure.
- Deployments must set: non-root `securityContext`, `readOnlyRootFilesystem`
  where possible, requests + limits, readiness + liveness probes,
  `topologySpreadConstraints` across zones, a PDB.
- `image.tag` is always pinned to a Git SHA at deploy time; never
  `latest` in cluster manifests.

### App code

- Node 22, Express. Keep dependencies minimal — Express, that's it for the
  sample. Multi-stage Dockerfile, runs as non-root, exposes
  `/`, `/healthz`, `/readyz`.
- Image base: `node:22-alpine` for both stages. No `npm install` in
  runtime stage; copy `node_modules` from builder.

## What NOT to do

- Do **not** add a CI step that runs `terraform apply` from a PR — apply
  only on push to `dev` or `main` (or `workflow_dispatch`).
- Do **not** create new top-level folders without discussing with the
  user. The current top-level set is `app/`, `deploy/`, `infra/`,
  `.github/`, plus the docs at root.
- Do **not** destroy or rename Azure state resources, RGs, or the OIDC app
  reg without explicit user confirmation. Bootstrap is run-once.
- Do **not** introduce `kubernetes-sigs/ingress-nginx`, AGIC, or the AKS
  Application Routing add-on. Ingress is **AGC** with the in-cluster ALB
  Controller. See `README.md` § "Which ingress — and why *not* NGINX?"
  for the full rationale.

## Tests / verification commands you can rely on

```sh
# Terraform
terraform -chdir=infra fmt -recursive -check
terraform -chdir=infra validate
terraform -chdir=infra init  -backend-config=envs/backends/dev.hcl -reconfigure
terraform -chdir=infra plan  -var-file=envs/dev.tfvars

# App
cd app && npm ci && npm test       # (when tests exist)
docker build -t web:dev .

# Helm
helm lint  deploy/chart -f deploy/chart/values-dev-weu.yaml
helm template web deploy/chart -f deploy/chart/values-dev-weu.yaml | kubectl --dry-run=client apply -f -
```

## Asking for help

If a task implies changing any of the hard rules above (provider versions,
ingress choice, layout, branch model), pause and confirm with the user
before editing — those choices are load-bearing for the wider project.
