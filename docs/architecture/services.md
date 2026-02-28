# Microservices Interaction

## Service Communication Map

Services communicate via HTTP invocation and Kafka pub/sub.

```mermaid
graph LR
    subgraph Interfaces
        UI[UI Web<br/>React SPA]
        ChatGPT[UI ChatGPT<br/>OpenAI Actions]
    end

    subgraph Ory Stack
        OK[Oathkeeper<br/>API Gateway]
        KR[Kratos<br/>Identity]
    end

    subgraph Business Services
        Mentor[Mentor<br/>Go / stdlib]
        Profile[Profile<br/>Go / Gin / GORM]
        Task[Task<br/>Go / Gin / GORM]
    end

    subgraph AI Engine
        LLM[LLM Taskgen<br/>LLM SDKs]
        Validator[Solution Validator<br/>SymPy]
    end

    subgraph Data Stores
        PG[(PostgreSQL)]
        Redis[(Redis)]
        Kafka[[Kafka]]
    end

    subgraph Secrets
        Vault[HashiCorp Vault]
        ESO[External Secrets<br/>Operator]
    end

    UI -->|auth| OK
    ChatGPT -->|auth| OK
    OK -->|validated| KR

    UI -->|HTTP| Task
    UI -->|HTTP| Validator
    ChatGPT -->|HTTP| Task

    Mentor -->|HTTP| Profile
    Task -->|HTTP| LLM

    KR -->|webhook| Profile

    Mentor -.->|pub: mentor.strategy.updated| Kafka
    Task -.->|sub: mentor.strategy.updated| Kafka
    Task -.->|pub: task.attempt.completed| Kafka
    Profile -.->|sub: task.attempt.completed| Kafka
    Mentor -.->|sub: task.attempt.completed| Kafka

    Profile --> PG
    Profile --> Redis
    Task --> PG

    ESO -->|sync secrets| Vault
    ESO -.->|K8s Secrets| Profile
    ESO -.->|K8s Secrets| Task

    classDef svc fill:#5b21b6,stroke:#7c3aed,color:#fff
    classDef storage fill:#0e7490,stroke:#06b6d4,color:#fff
    classDef ory fill:#b45309,stroke:#f59e0b,color:#fff
    classDef ui fill:#047857,stroke:#10b981,color:#fff
    classDef ai fill:#be185d,stroke:#ec4899,color:#fff
    classDef secret fill:#4338ca,stroke:#818cf8,color:#fff

    class Mentor,Profile,Task svc
    class PG,Redis,Kafka storage
    class OK,KR ory
    class UI,ChatGPT ui
    class LLM,Validator ai
    class Vault,ESO secret
```

## Communication Patterns

### Service Invocation (Synchronous HTTP)

| Caller | Target | Method | Purpose |
|--------|--------|--------|---------|
| Mentor | Profile | `GET /profiles/{id}` | Read student data for strategy |
| Task | LLM Taskgen | `POST /generate` | Generate math problem |
| UI Web | Task | `GET /tasks/next` | Get next task for student |
| UI Web | Validator | `POST /validate` | Submit solution |

### Pub/Sub (Asynchronous via Kafka)

| Publisher | Topic | Subscribers | Purpose |
|-----------|-------|------------|---------|
| Kratos (webhook) | `identity.registration.completed` | Profile | Auto-create student profile |
| Mentor | `mentor.strategy.updated` | Task | Pass generation parameters |
| Task | `task.attempt.completed` | Profile, Mentor | Update skills/XP, re-evaluate strategy |

## Secrets Flow (Bank-Vaults + ESO)

Vault is managed by the **Bank-Vaults Operator** via a declarative Custom Resource (`kind: Vault`).
The operator handles initialization, auto-unseal (keys stored in K8s Secret), and configuration
reconciliation. All Vault settings (auth methods, policies, secrets engines, database roles) are
defined in `infra/manifests/vault-instance.yaml`.

Two types of secrets are delivered to services via ESO:

### Dynamic Database Credentials (Database Secrets Engine)

```mermaid
graph LR
    V[Vault<br/>Bank-Vaults CR] -->|K8s Auth| ESO[External Secrets<br/>Operator]
    ESO -->|ClusterSecretStore:<br/>vault-backend| DB[Database Engine]
    DB -->|dynamic lease| M[K8s Secret:<br/>mentor-api-db-dynamic-creds]
    DB -->|dynamic lease| P[K8s Secret:<br/>profile-api-db-dynamic-creds]

    M -->|connectionString| Mentor[Mentor Pod]
    P -->|connectionString| Profile[Profile Pod]

    classDef vault fill:#4338ca,stroke:#818cf8,color:#fff
    class V,ESO,DB vault
```

| Service | Vault Role | Database | TTL | Refresh |
|---------|-----------|----------|-----|---------|
| mentor-api | `mentor-api-role` | mentor | 1h | 55m |
| profile-api | `profile-api-role` | profile | 1h | 55m |
| task-api | `task-api-role` | mathtrail | 1h | 55m |

### Static KV Secrets (KV v2 Engine)

```mermaid
graph LR
    V[Vault<br/>Bank-Vaults CR] -->|K8s Auth| ESO[External Secrets<br/>Operator]
    ESO -->|ClusterSecretStore:<br/>vault-kv-backend| KV[KV v2 Engine]
    KV --> S1[K8s Secret:<br/>profile-secrets]
    KV --> S2[K8s Secret:<br/>identity-secrets]

    S1 -->|env mount| Profile[Profile Pod]
    S2 -->|env mount| Identity[Kratos Pod]

    classDef vault fill:#4338ca,stroke:#818cf8,color:#fff
    class V,ESO,KV vault
```

**Vault Path Convention**: `secret/data/{env}/{service}/{key}`

| Service | Keys |
|---------|------|
| mathtrail-profile | `db-password`, `redis-password` |
| mathtrail-task | `db-password` |
| mathtrail-identity | `kratos-dsn`, `hydra-dsn` |
| mathtrail-llm-taskgen | `llm-api-key` |
