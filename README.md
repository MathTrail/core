# MathTrail

AI platform that helps students learn to solve math olympiad problems through personalized adaptive learning.

See [project overview](docs/project-overview.md) for architecture details.
See [workspace setup](docs/workspace.md) for getting started.

## Project Structure

| Group | Repository | Description |
|-------|-----------|-------------|
| **Foundation** | [mathtrail](.) | Workspace hub: Skaffold orchestrator, docs, diagrams |
| | [mathtrail-service-template](../mathtrail-service-template) | Golden template for new microservices (infra/, CI/CD) |
| **Business** | [mathtrail-identity](../mathtrail-identity) | Authentication & authorization (Ory Kratos/Hydra/Keto/Oathkeeper) |
| | [mathtrail-profile](../mathtrail-profile) | Student knowledge graph, progress history, XP tracking |
| | [mathtrail-mentor](../mathtrail-mentor) | AI strategist — learning strategy, skill gap analysis |
| | [mathtrail-task](../mathtrail-task) | Task orchestrator — turns Mentor parameters into problems |
| **AI & Engine** | [mathtrail-llm-taskgen](../mathtrail-llm-taskgen) | LLM connector for math problem generation |
| | [mathtrail-solution-validator](../mathtrail-solution-validator) | Solution checking engine (symbolic math, logic) |
| **Interfaces** | [mathtrail-ui-web](../mathtrail-ui-web) | Student web app (React/Vite/Tailwind/shadcn) |
| | [mathtrail-ui-chatgpt](../mathtrail-ui-chatgpt) | ChatGPT plugin / custom GPTs integration |
| **Infrastructure** | [mathtrail-infra](../mathtrail-infra) | Global manifests: Vault, ESO, Telepresence |
| | [mathtrail-charts](../mathtrail-charts) | Centralized Helm chart repository (GitHub Pages) |
| | [mathtrail-gitops](../mathtrail-gitops) | Centralized GitOps: ArgoCD App-of-Apps, releases, environments |
| | [mathtrail-infra-local](../mathtrail-infra-local) | Local dev infra: PostgreSQL, Redis, Kafka |
| | [mathtrail-infra-local-k3s](../mathtrail-infra-local-k3s) | K3d cluster creation and kubeconfig |
| | [mathtrail-infra-observability](../mathtrail-infra-observability) | Grafana LGTM, OpenTelemetry, Pyroscope |
| | [mathtrail-infra-testing](../mathtrail-infra-testing) | E2E & load testing (k6 operator) |

## Architecture Documentation

| Diagram | Description |
|---------|-------------|
| [Microservices Interaction](docs/architecture/services.md) | Service communication map, HTTP invocation & Kafka pub/sub topics, secrets flow |
| [Identity & Auth Flow](docs/architecture/identity.md) | Ory stack architecture, registration/login/authorization sequence diagrams |
| [GitOps & Deployment](docs/architecture/deployment.md) | Code-to-runtime pipeline, App-of-Apps pattern, three deployment scenarios |
| [Observability Stack](docs/architecture/observability.md) | Telemetry pipeline, OTel Collector config, Grafana LGTM + Pyroscope |
