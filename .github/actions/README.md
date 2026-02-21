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

```bash
# 1. Create the exact version tag
git tag v1.2.0

# 2. Move the major tag to the same commit
git tag -f v1

# 3. Push both tags (--force is required for the moved tag)
git push origin v1.2.0 v1 --force
```

### Example: first release

```bash
git tag v1.0.0
git tag v1
git push origin v1.0.0 v1
```

### Example: subsequent release

```bash
git tag v1.1.0
git tag -f v1
git push origin v1.1.0 v1 --force
```

> **Why `--force`?** Git does not allow moving an existing tag without `-f` locally and `--force` on push. This is safe because `v1` is a well-known floating alias, not an immutable release.
