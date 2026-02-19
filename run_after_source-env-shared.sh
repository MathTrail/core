#!/bin/bash
# Ensure ~/.env.shared is sourced in every bash session
MARKER="# source env.shared (managed by chezmoi)"
if ! grep -qF "$MARKER" "$HOME/.bashrc" 2>/dev/null; then
    cat >> "$HOME/.bashrc" <<'EOF'

# source env.shared (managed by chezmoi)
if [ -f "$HOME/.env.shared" ]; then
    set -a
    . "$HOME/.env.shared"
    set +a
fi
EOF
    echo "Added env.shared sourcing to ~/.bashrc"
fi
