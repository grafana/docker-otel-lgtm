# Releasing

## Publish Release via Github Workflow

### Create a Release

1. switch to the `main` branch.
2. Create and push a version.

```sh
git checkout main
git tag -a v<VERSION> -m "Release v<VERSION>"
git push origin v<VERSION>
```
