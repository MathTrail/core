# Observability Stack

## Telemetry Pipeline

```mermaid
graph LR
    subgraph Application Pods
        S1[Profile<br/>+ Dapr Sidecar]
        S2[Mentor<br/>+ Dapr Sidecar]
        S3[Task<br/>+ Dapr Sidecar]
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

    S1 -->|Zipkin traces| OTel
    S2 -->|Zipkin traces| OTel
    S3 -->|Zipkin traces| OTel
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
    participant DS as Dapr Sidecar
    participant Svc as Service
    participant OTel as OTel Collector
    participant Tempo as Tempo

    UI->>DS: HTTP request (trace context)
    DS->>Svc: Forward + inject span
    DS->>OTel: Zipkin span (port 9411)
    Svc->>DS: Response
    DS->>OTel: Zipkin span (response)
    OTel->>Tempo: OTLP batch export
```

### Metrics

| Source | Protocol | Destination |
|--------|----------|-------------|
| Dapr sidecars | OTLP/gRPC | OTel Collector |
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
  - zipkin (port 9411)     ← Dapr traces
  - otlp (gRPC port 4317)  ← Metrics + Logs
  - filelog                 ← Container stdout

Processors:
  - k8sattributes          ← Add pod name, namespace, labels
  - batch                  ← Batch for efficiency

Exporters:
  - otlp → Grafana Alloy → Loki/Tempo/Mimir
```

## Dapr Telemetry Configuration

```yaml
# Dapr Configuration (applied via mathtrail-infra)
apiVersion: dapr.io/v1alpha1
kind: Configuration
metadata:
  name: mathtrail-config
spec:
  tracing:
    samplingRate: "1"
    zipkin:
      endpointAddress: "http://otel-collector.monitoring.svc.cluster.local:9411/api/v2/spans"
  metric:
    enabled: true
```

## Namespace Layout

| Namespace | Components |
|-----------|-----------|
| `mathtrail` | All application services + Dapr sidecars |
| `monitoring` | OTel Collector, Grafana, Loki, Tempo, Mimir, Pyroscope |
| `dapr-system` | Dapr control plane (operator, sentry, placement) |
