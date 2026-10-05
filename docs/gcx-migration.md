# Migration: generated MCP setup replaced by gcx guidance

Starting with the planned docker-otel-lgtm `v0.36.0` release (the next release
after `v0.35.0` as of 2026-10-05), the image will no longer generate MCP client
configuration or bootstrap credentials for AI tools. If `v0.36.0` ships without
this change, use the first later release that includes it. For local diagnosis,
use the [gcx workflow](gcx-integration.md); gcx and your agent run on your host,
not in the image.

This change removes image-specific token and configuration maintenance and
leaves you with one recommended troubleshooting path. MCP remains available in
Grafana and Tempo themselves.

## Removed image behavior

- Creation/lookup of the `ai-tools` Grafana service account and creation/rotation
  of its `ai-tools-token` token.
- Writing `/tmp/grafana-sa-token`, `/etc/lgtm/mcp.json`, and
  `/etc/lgtm/claude-mcp-setup.sh`.
- MCP setup commands and status messages in container startup output.

The bootstrap-only overrides `GRAFANA_URL`, `GRAFANA_PUBLIC_URL`, `TEMPO_URL`,
`LGTM_CONFIG_DIR`, and `GRAFANA_SA_TOKEN_FILE` no longer configure any image
behavior. The launch scripts no longer pass `CONTAINER_RUNTIME` into the image
for generated setup commands; Docker/Podman runtime selection still works.
This does not change similarly named environment variables in external tools.

If your automation reads the generated files, update it before moving to the
first release that includes this change. The replacement guide shows how to
configure gcx directly against Grafana; it does not need those files or the
bootstrap-managed token.

## Existing credentials and client configuration

Upgrading does **not** delete existing Grafana service accounts, revoke tokens,
edit your host MCP client configuration, or remove user-mounted copies of the
old generated files. Their presence is not evidence that the new image manages
or refreshes them.

Before cleaning up old client registrations or credentials, check whether any
other workflow still uses them. A token used elsewhere should not be revoked
just because this image no longer creates it. Where practical, give gcx
read-only access, and keep credentials out of chat and committed files.

## Preserved functionality

- `TEMPO_EXTRA_ARGS` and other backend argument passthrough remain supported.
  Independently configured Tempo MCP endpoints are not disabled by this change.
- `OTEL_COLLECTOR_DEBUG_EXPORTER=true` remains available. See the gcx guide's
  [Collector receipt evidence](gcx-integration.md#optional-collector-receipt-evidence)
  for logging options, payload sensitivity, and restoration.
- Component ports, readiness, shutdown handling, and ordinary LGTM use remain
  independent of gcx or an agent.

## Release-note summary

This change removes the image's creation of AI-tool service-account tokens and
generation of MCP client files. Configure host-side gcx using the [gcx
workflow](gcx-integration.md). Upgrading will not delete existing credentials
or user-mounted files; check whether you still need them before removing them.
