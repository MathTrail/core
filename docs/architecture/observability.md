# Observability Stack

## Telemetry Pipeline

```mermaid
graph LR
    subgraph Application Pods
        S1[Profile]
        S2[Mentor]
        S3[Task]
        S4[Identity UI]
    end

    subgraph Collection
        OTel[OpenTelemetry<br/>Collector]
    end

    subgraph Grafana LGTM
        Loki[Loki<br/>Logs]
        Tempo[Tempo<br/>Traces]
        Mimir[Mimir<br/>Metrics]
        Grafana[Grafana<br/>Dashboards]
    end

    subgraph Profiling
        Pyro[Pyroscope<br/>Continuous Profiling]
    end

    S1 -->|OTLP traces| OTel
    S2 -->|OTLP traces| OTel
    S3 -->|OTLP traces| OTel
    S1 -->|OTLP metrics| OTel
    S2 -->|OTLP metrics| OTel
    S3 -->|OTLP metrics| OTel
    S1 -->|OTLP logs| OTel
    S2 -->|OTLP logs| OTel
    S3 -->|OTLP logs| OTel

    S1 -.->|push profiles| Pyro
    S2 -.->|push profiles| Pyro
    S3 -.->|push profiles| Pyro

    OTel -->|OTLP export| Loki
    OTel -->|OTLP export| Tempo
    OTel -->|OTLP export| Mimir

    Loki --> Grafana
    Tempo --> Grafana
    Mimir --> Grafana
    Pyro --> Grafana

    classDef app fill:#5b21b6,stroke:#7c3aed,color:#fff
    classDef collect fill:#b45309,stroke:#f59e0b,color:#fff
    classDef grafana fill:#047857,stroke:#10b981,color:#fff
    classDef profile fill:#be185d,stroke:#ec4899,color:#fff

    class S1,S2,S3,S4 app
    class OTel collect
    class Loki,Tempo,Mimir,Grafana grafana
    class Pyro profile
```

## Data Flow Details

### Traces (Distributed Tracing)

```mermaid
sequenceDiagram
    participant UI as UI Web
    participant Svc as Service
    participant OTel as OTel Collector
    participant Tempo as Tempo

    UI->>Svc: HTTP request (trace context)
    Svc->>OTel: OTLP spans (port 4317)
    Svc->>UI: Response
    OTel->>Tempo: OTLP batch export
```

### Metrics

| Source | Protocol | Destination |
|--------|----------|-------------|
| Go services (OTel SDK) | OTLP/gRPC | OTel Collector |
| Go services | Prometheus endpoint | OTel Collector (scrape) |
| OTel Collector | OTLP/gRPC | Mimir |

### Logs

| Source | Protocol | Destination |
|--------|----------|-------------|
| All pods | stdout/stderr | OTel Collector (filelog receiver) |
| OTel Collector | OTLP/gRPC | Loki |

### Profiling

| Source | Protocol | Destination |
|--------|----------|-------------|
| Go services | pyroscope-go SDK (push) | Pyroscope |

## OTel Collector Configuration

The collector acts as a **smart gateway** with k8sattributes processor for metadata enrichment:

```
Receivers:
  - zipkin (port 9411)     ← Legacy Zipkin traces
  - otlp (gRPC port 4317)  ← Metrics + Logs + Traces
  - filelog                 ← Container stdout

Processors:
  - k8sattributes          ← Add pod name, namespace, labels
  - batch                  ← Batch for efficiency

Exporters:
  - otlp → Grafana Alloy → Loki/Tempo/Mimir
```

## Application Tracing Configuration

Services export traces via the OTel SDK to the OTel Collector. The Zipkin receiver is
retained for backward compatibility.

## Namespace Layout

| Namespace | Components |
|-----------|-----------|
| `mathtrail` | All application services |
| `monitoring` | OTel Collector, Grafana, Loki, Tempo, Mimir, Pyroscope |
