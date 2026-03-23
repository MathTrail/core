# MathTrail — Root Workspace

## Identity & Context

This is the MathTrail root workspace — the central orchestrator for a multi-repo microservice ecosystem.  
This repo contains: Skaffold orchestrator (`skaffold.yaml`), documentation (`docs/`), VS Code workspace config, `justfile` recipes, shared platform env (`platform-env/`), and devcontainer config.  
It does **not** contain application code. It coordinates deployments of all child services.

**Tech stack:** Skaffold v4beta13, Helm, Just, k3d, Docker  
**Infra:** No `infra/` here — infrastructure lives in dedicated repos (see below)

## Repo Structure

```
justfile                  # Task runner — dotenv from platform-env/global.env
skaffold.yaml             # Multi-config orchestrator (requires → child repos)
mathtrail.code-workspace  # VS Code multi-root workspace
platform-env/
  global.env              # Single source of truth for platform constants
  Dockerfile              # scratch image — published to GHCR
  README.md
docs/                     # Architecture & setup documentation
plans/                    # Implementation plans
.devcontainer/            # Dev container (kubectl, helm, just)
.github/workflows/
  publish-platform-env.yml  # CI: build+push platform-env image on tag
```

## Platform Env (`platform-env/global.env`)

Single source of truth for shared constants. Published as a Docker scratch image (`ghcr.io/mathtrail/platform-env`) so child services can `COPY --from` at build time. Versioned via git tags `platform-env/vX.Y.Z`.

Key variables: `NAMESPACE`, `CLUSTER_NAME`, `REGISTRY`, `REGISTRY_CLUSTER`, `CHARTS_REPO`, `GITHUB_ORG`.

The justfile loads this file via `set dotenv-path := "platform-env/global.env"`.  
The devcontainer `post-start.sh` expects it at `/etc/mathtrail/platform.env` (copied during image build).

## Skaffold Modules

`skaffold.yaml` defines named configs wired via `requires` to sibling repos (`../mathtrail-*`):

| Module | Refs |
|--------|------|
| `mathtrail` (root) | → `all-infra` + `all-services` |
| `all-infra` | → `infra`, `infra-local`, `infra-observability`, `infra-testing`, `infra-chaos` |
| `all-services` | → `identity`, `mentor`, `profile` |
| `infra` | → `../mathtrail-infra` |
| `infra-local` | → `../mathtrail-infra-local` |
| `infra-observability` | → `../mathtrail-infra-observability` |
| `infra-testing` | → `../mathtrail-infra-testing` |
| `infra-chaos` | → `../mathtrail-infra-chaos` |
| `identity` | → `../mathtrail-identity` |
| `mentor` | → `../mathtrail-mentor` |
| `profile` | → `../mathtrail-profile` |

## Justfile Recipes

```
just deploy-all          # skaffold run (all modules)
just delete-all          # skaffold delete (all modules)
just deploy <MODULE>     # skaffold run -m <MODULE>
just delete <MODULE>     # skaffold delete -m <MODULE>
```

Example: `just deploy identity`, `just deploy all-infra`.

## Repository Map

| Group | Repository | Description |
|-------|-----------|-------------|
| **Foundation** | `mathtrail` (this repo) | Workspace hub: Skaffold orchestrator, docs |
| | `mathtrail-service-template` | Golden template for new microservices |
| **Business** | `mathtrail-identity` | Auth (Ory Kratos / Hydra / Keto / Oathkeeper) |
| | `mathtrail-profile` | Student knowledge graph, progress, XP (Go / Gin / GORM) |
| | `mathtrail-mentor` | AI strategist — learning strategy, skill gap analysis (Go / stdlib) |
| | `mathtrail-task` | Task orchestrator — turns Mentor params into problems (Go / Gin / GORM) |
| **AI & Engine** | `mathtrail-llm-taskgen` | LLM connector for math problem generation |
| | `mathtrail-solution-validator` | Solution checking (SymPy) |
| **Interfaces** | `mathtrail-ui-web` | Student web app (React / Vite / Tailwind / shadcn) |
| | `mathtrail-ui-chatgpt` | ChatGPT plugin / custom GPTs |
| **Infrastructure** | `mathtrail-infra` | Global manifests: Vault, ESO, Telepresence |
| | `mathtrail-charts` | Centralized Helm chart repo (GitHub Pages) |
| | `mathtrail-gitops` | ArgoCD App-of-Apps, releases, environments |
| | `mathtrail-infra-local` | Local dev: PostgreSQL, Redis |
| | `mathtrail-infra-local-k3s` | K3d cluster creation and kubeconfig |
| | `mathtrail-infra-observability` | Grafana LGTM, OpenTelemetry, Pyroscope |
| | `mathtrail-infra-testing` | E2E & load testing (k6 operator) |
| | `mathtrail-infra-chaos` | Chaos engineering |

> **Note:** `task`, `llm-taskgen`, `solution-validator`, `ui-web`, `ui-chatgpt` are planned but not yet wired into `skaffold.yaml`.

## Communication Map

Services communicate via HTTP invocation and Kafka pub/sub.

Key flows:
- **Mentor → Profile** (HTTP): read student data for strategy
- **Task → LLM Taskgen** (HTTP): generate math problem
- **Mentor → Kafka** (`mentor.strategy.updated`): Task subscribes
- **Task → Kafka** (`task.attempt.completed`): Profile & Mentor subscribe
- **Kratos webhook → Profile**: auto-create student profile on registration

## Devcontainer

- **Image:** Custom Dockerfile (`.devcontainer/Dockerfile`)
- **Features:** kubectl 1.31.0, Helm 3.14.0, Just
- **Workspace mount:** Parent dir mounted at `/workspaces`, workspaceFolder = `/workspaces/core`
- **Kubeconfig:** `~/.kube/k3d-mathtrail-dev.yaml` (copied from host bind mount by `post-start.sh`)
- **post-start.sh:** Copies kubeconfig, rewrites API server to `host.docker.internal`, adds registry host to `/etc/hosts`, sources `/etc/mathtrail/platform.env`

## Development Standards

- Documentation must stay in sync with child repos
- Skaffold profiles use JSON Patch (`op: replace`) — `requires` is NOT allowed inside profiles
- All child configs are referenced via `requires` at top level, swapped via profile patches
- Use relative paths (`../mathtrail-*/`) for cross-repo references

## Commit Convention

Conventional Commits with scope `workspace`:
```
feat(workspace): add new profile to skaffold
docs(workspace): update service communication map
chore(workspace): bump skaffold API version
```

## Testing

No application tests in this repo.
- Verify Skaffold configs: `skaffold diagnose`
- Verify docs: manual review of links and accuracy
