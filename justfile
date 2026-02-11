# MathTrail Root Orchestrator

set shell := ["bash", "-c"]

NAMESPACE := "mathtrail"

# ── Full Stack (no profile = deploy all) ─────────────────────

# Dev mode for everything with hot-reload
dev-all:
    skaffold dev --port-forward

# Deploy everything one-shot
deploy-all:
    skaffold run

# Delete everything
delete-all:
    skaffold delete

# ── Selective Deployment (by profile) ────────────────────────

# Dev mode for a profile (e.g. just dev mentor, just dev all-infra)
dev PROFILE:
    skaffold dev -p {{ PROFILE }} --port-forward

# Deploy a profile
deploy PROFILE:
    skaffold run -p {{ PROFILE }}

# Delete a profile
delete PROFILE:
    skaffold delete -p {{ PROFILE }}

# ── Status & Debug ───────────────────────────────────────────

# Show pods and services
status:
    #!/bin/bash
    echo "=== Pods ==="
    kubectl get pods -n {{ NAMESPACE }}
    echo ""
    echo "=== Services ==="
    kubectl get svc -n {{ NAMESPACE }}
    echo ""
    echo "=== Helm Releases ==="
    helm list -n {{ NAMESPACE }}
    helm list -n dapr-system 2>/dev/null || true

# Follow logs for a service
logs SERVICE:
    kubectl logs -l app.kubernetes.io/name={{ SERVICE }} -n {{ NAMESPACE }} -f

# List available profiles
profiles:
    @echo "Profiles (use with: just dev <profile> / just deploy <profile>):"
    @echo ""
    @echo "  Infrastructure:"
    @echo "    infra          Dapr runtime + components"
    @echo "    infra-local    PostgreSQL, Redis, Kafka (Strimzi)"
    @echo "    infra-testing  k6-operator"
    @echo "    all-infra      All infrastructure"
    @echo ""
    @echo "  Services:"
    @echo "    mentor         Mentor service"
    @echo "    profile        Profile service"
    @echo "    all-services   All services"
    @echo ""
    @echo "  No profile = deploy everything:"
    @echo "    just dev-all   Dev mode for full stack"
    @echo "    just deploy-all"
