# CLAUDE.md

Guidance for Claude Code working in this repository.

The canonical agent instructions live in [`AGENTS.md`](./AGENTS.md) — read
that first. It covers tooling versions, repo layout, naming conventions,
branch/workflow rules, coding conventions, and explicit "do nots".

For project context and the decision history that shaped the architecture,
see [`README.md`](./README.md).

For execution-level detail (modules, resources, exact wiring), see
[`.claude/plans/indexed-spinning-rivest.md`](./.claude/plans/indexed-spinning-rivest.md).

## Quick orientation

- Single Terraform root module at `infra/`. Env via tfvars + backend HCL —
  no per-env or per-region folders.
- `dev` branch → dev env; `main` branch → prd env.
- Ingress is **Application Gateway for Containers (AGC)**, not NGINX
  (ingress-nginx is EOL since March 2026).
- Cluster-side workloads are installed via Helm in workflow jobs, not in
  Terraform.

## When unsure

If a request would change provider versions, the ingress choice, the repo
layout, or the branch model: stop and confirm with the user. Those
decisions are load-bearing.
