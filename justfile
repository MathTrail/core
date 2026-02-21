# MathTrail Root Orchestrator

set shell := ["bash", "-c"]
set dotenv-load
set dotenv-path := "platform-env/global.env"
set export

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

# ── Versioning (composite actions) ───────────────────────────

# Release a new version: just release patch|minor|major
release BUMP:
    #!/usr/bin/env bash
    set -euo pipefail
    # Find latest vX.Y.Z tag
    latest=$(git tag --list 'v[0-9]*.[0-9]*.[0-9]*' --sort=-v:refname | head -n1)
    if [[ -z "$latest" ]]; then
        echo "No existing vX.Y.Z tag found — starting from v0.0.0"
        latest="v0.0.0"
    fi
    # Parse version components
    version="${latest#v}"
    IFS='.' read -r major minor patch <<< "$version"
    case "{{ BUMP }}" in
        patch) patch=$((patch + 1)) ;;
        minor) minor=$((minor + 1)); patch=0 ;;
        major) major=$((major + 1)); minor=0; patch=0 ;;
        *) echo "Error: invalid bump type '{{ BUMP }}' (use patch, minor, or major)"; exit 1 ;;
    esac
    new_tag="v${major}.${minor}.${patch}"
    major_tag="v${major}"
    echo "Bumping ${latest} → ${new_tag} (floating alias: ${major_tag})"
    git tag "${new_tag}"
    git tag -f "${major_tag}"
    git push origin "${new_tag}" "${major_tag}" --force
    echo "Done — created ${new_tag} and moved ${major_tag}"
