# MathTrail — Root Workspace

## Identity & Context

This is the MathTrail root workspace — the central orchestrator for a multi-repo microservice ecosystem.  
This repo contains: Skaffold orchestrator (`skaffold.yaml`), documentation (`docs/`), VS Code workspace config, and `justfile` recipes.  
It does **not** contain application code. It coordinates deployments of all child services.

**Tech stack:** Skaffold v4beta13, Helm, Just, Markdown, chezmoi  
**Infra:** No `infra/` here — infrastructure lives in dedicated repos (see below)

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
| **Infrastructure** | `mathtrail-infra` | Global manifests: Dapr, Vault, ArgoCD, Ingress |
| | `mathtrail-charts` | Centralized Helm chart repo (GitHub Pages) |
| | `mathtrail-gitops` | ArgoCD App-of-Apps, releases, environments |
| | `mathtrail-infra-local` | Local dev: PostgreSQL, Redis, Kafka (Strimzi) |
| | `mathtrail-infra-local-k3s` | K3d cluster creation and kubeconfig |
| | `mathtrail-infra-observability` | Grafana LGTM, OpenTelemetry, Pyroscope |
| | `mathtrail-infra-testing` | E2E & load testing (k6 operator) |
| | `mathtrail-infra-chaos` | Chaos engineering |

## Communication Map

All inter-service communication goes through **Dapr sidecars** — services never call each other directly.

Key flows:
- **Mentor → Profile** (Dapr invoke): read student data for strategy
- **Task → LLM Taskgen** (Dapr invoke): generate math problem
- **Mentor → Kafka** (`mentor.strategy.updated`): Task subscribes
- **Task → Kafka** (`task.attempt.completed`): Profile & Mentor subscribe
- **Kratos webhook → Profile**: auto-create student profile on registration

## Development Standards

- Documentation must stay in sync with child repos
- Skaffold profiles use JSON Patch (`op: replace`) — `requires` is NOT allowed inside profiles
- All child configs are referenced via `requires` at top level, swapped via profile patches
- Use relative paths (`../mathtrail-*/`) for cross-repo references
- Use `justfile` recipes for common operations (`just dev mentor`, `just deploy all-infra`, etc.)

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
