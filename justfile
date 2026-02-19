# MathTrail Root Orchestrator

set shell := ["bash", "-c"]
set dotenv-load := true
set dotenv-path := env("HOME") + "/.env.shared"

NAMESPACE := env_var("NAMESPACE")

# ── Full Stack (no profile = deploy all) ─────────────────────

# Deploy everything one-shot
deploy-all:
    skaffold run

# Delete everything
delete-all:
    skaffold delete

# ── Selective Deployment (by module) ─────────────────────────

# Deploy a module
deploy MODULE:
    skaffold run -m {{ MODULE }}

# Delete a module
delete MODULE:
    skaffold delete -m {{ MODULE }}
