# MathTrail Root Orchestrator

set shell := ["bash", "-c"]

ansible_min := "2.20.3"
set dotenv-load
set dotenv-path := "platform-env/global.env"
set export

NAMESPACE := env_var("NAMESPACE")

# List available recipes
[private]
default:
    @just --list

# ── Local Machine Provisioning ───────────────────────────────

# Provision local machine: check Ansible, install deps, run playbook
provision: _check-ansible _install-ansible-deps _run-playbook

[private]
_check-ansible:
    #!/usr/bin/env bash
    set -euo pipefail
    if ! command -v pipx &>/dev/null; then
        echo "pipx not found. Installing via apt..."
        sudo apt-get install -y pipx
        pipx ensurepath
    fi
    if ! command -v ansible &>/dev/null; then
        echo "Ansible not found. Installing via pipx..."
        pipx install "ansible-core>={{ ansible_min }}"
    else
        installed=$(ansible --version | head -1 | grep -oP '[\d]+\.[\d]+\.[\d]+')
        required="{{ ansible_min }}"
        if [ "$(printf '%s\n' "$required" "$installed" | sort -V | head -1)" != "$required" ]; then
            echo "Ansible $installed is outdated (need >=$required). Upgrading..."
            pipx upgrade ansible-core
        else
            echo "Ansible $installed ✓"
        fi
    fi

[private]
_install-ansible-deps:
    ansible-galaxy collection install \
        -r ansible/requirements.yml \
        --force

[private]
_run-playbook:
    ansible-playbook \
        -i ansible/inventory/local.yml \
        --ask-become-pass \
        ansible/playbooks/site.yml

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
