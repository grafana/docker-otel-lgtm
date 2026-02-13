# Renovate Tracked Deps Linter

## Why this exists

Renovate silently stops tracking a dependency when it can no longer parse the
version reference (typo in a comment annotation, unsupported syntax, moved
file, etc.). When that happens, the dependency freezes in place with no PR and
no dashboard entry — it simply disappears from Renovate's radar.

The Dependency Dashboard catches *known* dependencies that are pending or in error, but
it cannot show you a dependency that Renovate no longer sees at all. This linter
closes that gap by keeping a committed snapshot of every dependency Renovate
tracks and failing CI when the two diverge.

## How it works

1. **`mise run generate:renovate-tracked-deps`**
   (`.mise/tasks/generate/renovate-tracked-deps.py`)
   Runs Renovate locally in `--platform=local` mode, parses its debug log for
   the `packageFiles with updates` message, and writes the full dependency list
   (grouped by file and manager) to `.github/renovate-tracked-deps.json`.

2. **`mise run lint:renovate-deps`**
   (`.mise/tasks/lint/renovate-deps.py`)
   Re-generates the snapshot into a temp directory and diffs it against the
   committed `.github/renovate-tracked-deps.json`. If they differ, CI fails
   with a unified diff showing exactly which dependencies were added or removed.

## Typical workflow

- **A dependency disappears** (e.g., someone removes a `# renovate:` comment
  or changes a file that Renovate was matching) → CI fails, showing the
  removed dependency in the diff. The author can then decide whether the removal was
  intentional or accidental.

- **A new dependency is added** → CI fails because the committed snapshot is
  stale. Run `mise run generate:renovate-tracked-deps` and commit the updated
  JSON file.

- **Routine regeneration** → After any change to `renovate.json5`, Dockerfiles,
  `go.mod`, `package.json`, or other files Renovate scans, regenerate and
  commit the snapshot.

## Configuration

The `RENOVATE_TRACKED_DEPS_EXCLUDE` environment variable (set in `mise.toml`) lists
Renovate managers to exclude from tracking (comma-separated). Currently
`github-actions` and `github-runners` are excluded because their churn adds
noise without much risk of silent loss.
