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

# Release core: just release-core patch|minor|major
release-core BUMP: (_bump "v" BUMP "true")

# Release platform-env: just release-platform-env patch|minor|major
release-platform-env BUMP: (_bump "platform-env/v" BUMP)

[private]
_bump PREFIX BUMP FLOAT_MAJOR="false":
    #!/usr/bin/env bash
    set -euo pipefail
    prefix="{{ PREFIX }}"
    float_major="{{ FLOAT_MAJOR }}"
    # Find latest tag matching prefix
    latest=$(git tag --list "${prefix}[0-9]*.[0-9]*.[0-9]*" --sort=-v:refname | head -n1)
    if [[ -z "$latest" ]]; then
        echo "No existing ${prefix}X.Y.Z tag found — starting from ${prefix}0.0.0"
        latest="${prefix}0.0.0"
    fi
    # Parse version components
    version="${latest#"$prefix"}"
    IFS='.' read -r major minor patch <<< "$version"
    case "{{ BUMP }}" in
        patch) patch=$((patch + 1)) ;;
        minor) minor=$((minor + 1)); patch=0 ;;
        major) major=$((major + 1)); minor=0; patch=0 ;;
        *) echo "Error: invalid bump type '{{ BUMP }}' (use patch, minor, or major)"; exit 1 ;;
    esac
    new_tag="${prefix}${major}.${minor}.${patch}"
    if [[ "$float_major" == "true" ]]; then
        major_tag="${prefix}${major}"
        echo "Bumping ${latest} → ${new_tag} (floating alias: ${major_tag})"
        git tag "${new_tag}"
        git tag -f "${major_tag}"
        git push origin "${new_tag}" "${major_tag}" --force
        echo "Done — created ${new_tag} and moved ${major_tag}"
    else
        echo "Bumping ${latest} → ${new_tag}"
        git tag "${new_tag}"
        git push origin "${new_tag}"
        echo "Done — created ${new_tag}"
    fi
