# Identity Flow

## Authentication Architecture

MathTrail uses the Ory stack for identity management. All auth flows are cookie-based (no localStorage tokens).

```mermaid
graph TD
    subgraph Browser
        SPA[Identity UI<br/>React SPA]
    end

    subgraph Ory Stack
        OK[Oathkeeper<br/>API Gateway]
        KR[Kratos<br/>Identity Provider]
        HY[Hydra<br/>OAuth2 / OIDC]
        KE[Keto<br/>Permissions]
    end

    subgraph Services
        Profile[Profile Service]
        WebApp[UI Web]
    end

    subgraph Storage
        PG[(PostgreSQL<br/>kratos / hydra / keto DBs)]
    end

    SPA -->|same-origin proxy| KR
    SPA -->|OAuth2 consent| HY

    WebApp -->|every API call| OK
    OK -->|validate session| KR
    OK -->|check permissions| KE
    OK -->|pass through| Services

    KR -->|webhook: registration| Profile
    KR --> PG
    HY --> PG
    KE --> PG

    classDef ory fill:#b45309,stroke:#f59e0b,color:#fff
    classDef ui fill:#047857,stroke:#10b981,color:#fff
    classDef svc fill:#5b21b6,stroke:#7c3aed,color:#fff

    class OK,KR,HY,KE ory
    class SPA,WebApp ui
    class Profile svc
```

## Registration Flow

```mermaid
sequenceDiagram
    actor Student
    participant UI as Identity UI
    participant KR as Ory Kratos
    participant PG as PostgreSQL
    participant Profile as Profile Service

    Student->>UI: Click "Register"
    UI->>KR: GET /self-service/registration/browser
    KR-->>UI: Registration flow (CSRF token + ui.nodes)
    UI->>UI: Render form dynamically from ui.nodes

    Student->>UI: Fill email, password, name
    UI->>KR: POST /self-service/registration (form data)
    KR->>PG: Create identity
    KR-->>UI: Set session cookie (HttpOnly)

    KR->>Profile: Webhook: POST /webhooks/registration
    Profile->>Profile: Auto-create student profile (Knowledge Graph init)

    UI->>UI: Redirect to dashboard
```

## Login Flow

```mermaid
sequenceDiagram
    actor Student
    participant UI as Identity UI
    participant KR as Ory Kratos
    participant WebApp as UI Web

    Student->>UI: Click "Login"
    UI->>KR: GET /self-service/login/browser
    KR-->>UI: Login flow (CSRF token + ui.nodes)
    UI->>UI: Render login form

    Student->>UI: Enter credentials
    UI->>KR: POST /self-service/login (credentials)
    KR-->>UI: Set session cookie (HttpOnly)
    UI->>WebApp: Redirect to app

    WebApp->>KR: GET /sessions/whoami (cookie)
    KR-->>WebApp: Session + identity data
    WebApp->>WebApp: Initialize Zustand auth store
```

## API Authorization Flow

```mermaid
sequenceDiagram
    participant WebApp as UI Web
    participant OK as Oathkeeper
    participant KR as Kratos
    participant KE as Keto
    participant Task as Task Service

    WebApp->>OK: GET /api/tasks/next (session cookie)
    OK->>KR: Validate session
    KR-->>OK: Identity + session valid

    OK->>KE: Check permission (student, tasks, read)
    KE-->>OK: Allowed

    OK->>Task: Forward request (X-User-Id header)
    Task-->>OK: Task data
    OK-->>WebApp: Task data
```

## Key Principles

- **Cookie-First**: All auth uses HttpOnly session cookies, never localStorage
- **Same-Origin**: nginx proxy (prod) and Vite proxy (dev) keep SPA + Kratos on same origin
- **Dynamic Forms**: UI forms are built from Kratos `ui.nodes` — never hardcode fields
- **Zero-Trust API**: Every API call goes through Oathkeeper for session validation + Keto for permissions
