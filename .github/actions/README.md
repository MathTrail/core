# Composite Actions

Reusable composite GitHub Actions shared across MathTrail repositories.

## setup-env

Extracts platform variables from the `ghcr.io/mathtrail/platform-env` Docker image and loads them into `GITHUB_ENV`.

```yaml
- uses: mathtrail/core/.github/actions/setup-env@v1
```

The action references the image by **major tag** (`platform-env:1`), so all consumers automatically pick up patch/minor updates without changing their workflows.

## Versioning

The action follows **major-tag aliasing**: a floating `v1` tag always points to the latest `v1.x.x` release.

### Releasing a new version

From the repo root, run:

```bash
just release patch   # v1.0.0 → v1.0.1
just release minor   # v1.0.1 → v1.1.0
just release major   # v1.1.0 → v2.0.0
```

The recipe automatically:
1. Finds the latest `vX.Y.Z` tag
2. Bumps the requested component
3. Creates the new semver tag
4. Moves the major floating alias (`v1`, `v2`, …)
5. Pushes both tags to `origin`

<details>
<summary>Manual steps (for reference)</summary>

```bash
# 1. Create the exact version tag
git tag v1.2.0

# 2. Move the major tag to the same commit
git tag -f v1

# 3. Push both tags (--force is required for the moved tag)
git push origin v1.2.0 v1 --force
```

</details>

### Example: first release

```bash
just release minor   # → v1.0.0
```

### Example: subsequent release

```bash
just release minor   # v1.0.0 → v1.1.0
```

> **Why `--force`?** Git does not allow moving an existing tag without `-f` locally and `--force` on push. This is safe because `v1` is a well-known floating alias, not an immutable release.
