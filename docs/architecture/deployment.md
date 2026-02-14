# GitOps & Deployment Flow

## Code to Runtime Pipeline

```mermaid
graph TD
    subgraph Service Repos
        SR[Service Repo<br/>mathtrail-profile, mentor, ...]
        SH[infra/helm/svc/<br/>Chart.yaml + values.yaml]
        CI[GitHub Actions<br/>release-chart.yml]
    end

    subgraph Chart Repository
        CR[mathtrail-charts<br/>GitHub Pages]
        IX[charts/index.yaml]
        TGZ[charts/svc-0.2.0.tgz]
    end

    subgraph GitOps
        GO[mathtrail-gitops]
        RL[releases/<br/>platform-vX.yaml]
        SA[apps/services/<br/>profile.yaml, mentor.yaml, ...]
        IA[apps/infrastructure/<br/>dapr.yaml, vault.yaml, ...]
    end

    subgraph ArgoCD
        ROOT[Platform App<br/>App-of-Apps]
        SVC[Service Apps]
        INFRA[Infra Apps]
    end

    subgraph Kubernetes
        K8S_OP[On-Prem Cluster]
        K8S_CL[Cloud Cluster]
    end

    SR --> SH
    SH -->|push to main| CI
    CI -->|helm package| TGZ
    TGZ --> IX
    IX --> CR

    CR -.->|manual: update version| RL
    RL --> SA
    SA --> ROOT
    IA --> ROOT

    ROOT --> SVC
    ROOT --> INFRA
    SVC -->|sync| K8S_OP
    SVC -->|sync| K8S_CL
    INFRA -->|sync| K8S_OP
    INFRA -->|sync| K8S_CL

    classDef repo fill:#047857,stroke:#10b981,color:#fff
    classDef chart fill:#b45309,stroke:#f59e0b,color:#fff
    classDef gitops fill:#5b21b6,stroke:#7c3aed,color:#fff
    classDef argo fill:#be185d,stroke:#ec4899,color:#fff
    classDef k8s fill:#0e7490,stroke:#06b6d4,color:#fff

    class SR,SH,CI repo
    class CR,IX,TGZ chart
    class GO,RL,SA,IA gitops
    class ROOT,SVC,INFRA argo
    class K8S_OP,K8S_CL k8s
```

## Three Deployment Scenarios

```mermaid
graph LR
    subgraph Local Dev
        SK[Skaffold]
        K3D[K3d Cluster]
        DEV_V[values-dev.yaml<br/>hardcoded passwords]
    end

    subgraph On-Prem
        ARGO_OP[ArgoCD]
        K8S_OP[Bare-Metal K8s]
        OP_V[values-on-prem.yaml<br/>Vault + ESO]
    end

    subgraph Cloud
        ARGO_CL[ArgoCD]
        EKS[Managed K8s<br/>EKS / GKE]
        CL_V[values-cloud.yaml<br/>Vault + ESO + RDS]
    end

    SK -->|direct deploy| K3D
    DEV_V --> SK

    ARGO_OP -->|gitops sync| K8S_OP
    OP_V --> ARGO_OP

    ARGO_CL -->|gitops sync| EKS
    CL_V --> ARGO_CL

    classDef dev fill:#047857,stroke:#10b981,color:#fff
    classDef onprem fill:#b45309,stroke:#f59e0b,color:#fff
    classDef cloud fill:#5b21b6,stroke:#7c3aed,color:#fff

    class SK,K3D,DEV_V dev
    class ARGO_OP,K8S_OP,OP_V onprem
    class ARGO_CL,EKS,CL_V cloud
```

## App-of-Apps Pattern

```mermaid
graph TD
    ROOT[mathtrail-platform<br/>Root Application]

    subgraph Services
        P[Profile]
        M[Mentor]
        I[Identity]
        T[Task]
        LLM[LLM Taskgen]
        V[Validator]
        UW[UI Web]
        UC[UI ChatGPT]
    end

    subgraph Infrastructure
        D[Dapr]
        VLT[Vault]
        E[ESO]
        SC[StorageClass]
    end

    ROOT --> P
    ROOT --> M
    ROOT --> I
    ROOT --> T
    ROOT --> LLM
    ROOT --> V
    ROOT --> UW
    ROOT --> UC
    ROOT --> D
    ROOT --> VLT
    ROOT --> E
    ROOT --> SC

    classDef root fill:#be185d,stroke:#ec4899,color:#fff
    classDef svc fill:#5b21b6,stroke:#7c3aed,color:#fff
    classDef infra fill:#0e7490,stroke:#06b6d4,color:#fff

    class ROOT root
    class P,M,I,T,LLM,V,UW,UC svc
    class D,VLT,E,SC infra
```

## Release & Promotion Flow

```
Dev (local k3d)  →  On-Prem  →  Cloud
    Skaffold          ArgoCD      ArgoCD
    direct deploy     git sync    git sync
```

**Release manifest** (`mathtrail-gitops/releases/platform-vX.yaml`) pins all service versions:

```yaml
services:
  profile: 0.2.0
  mentor: 1.3.0
  identity: 0.5.0
  task: 0.1.0
```

**Promotion**: `git cherry-pick` release commit between environment branches.

**Rollback**: `git revert` the release commit in `mathtrail-gitops`.

## Progressive Delivery

- **Canary**: Deploy v2 → 10% traffic → metrics evaluation → 50% → 100%
- **Blue-Green**: Deploy parallel environment → manual promotion → instant rollback
- Controlled via `rollout` values in each service's Helm chart
