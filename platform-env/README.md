# platform-env

A minimal Docker image (`FROM scratch`) containing `global.env` — the **single source of truth** for MathTrail platform constants (namespace, registry, chart repo, etc.).

Other services copy this file at build time:

```dockerfile
COPY --from=ghcr.io/mathtrail/platform-env:1 /config/global.env /config/global.env
```

## Versioning

The image is versioned via **git tags** in the format `platform-env/vX.Y.Z` (semver).  
Major bump = breaking change (variable removed or renamed).

Pushing a tag triggers the **Publish platform-env** GitHub Actions workflow, which builds and publishes the image to GHCR.

## Creating and pushing a tag

From the root of the Core repository:

```bash
# 1. Create a local tag
git tag platform-env/v1.0.0

# 2. Push the tag to GitHub
git push origin platform-env/v1.0.0
```

### What happens next

`docker/metadata-action` takes the string `platform-env/v1.0.0` and generates Docker tags.  
The image becomes available under four names:

| Tag | Description |
|-----|-------------|
| `ghcr.io/mathtrail/platform-env:1.0.0` | full version |
| `ghcr.io/mathtrail/platform-env:1.0` | minor |
| `ghcr.io/mathtrail/platform-env:1` | major |
| `ghcr.io/mathtrail/platform-env:latest` | `type=raw` |

## Tips

**Verify:** go to the **Actions** tab in the GitHub repository — look for the *Publish platform-env* run.

**Delete a wrong tag:**

```bash
git tag -d platform-env/v1.0.0              # delete locally
git push --delete origin platform-env/v1.0.0 # delete from GitHub
```

**Annotated tags** (recommended for releases):

```bash
git tag -a platform-env/v1.0.0 -m "First release of platform environment"
```
