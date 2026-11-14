# Development

## Local HAProxy + Data Plane API

The official HAProxy Docker images include the Data Plane API. This repository ships a minimal `docker-compose.yml` with sample configs in `dev/haproxy/`.

```bash
docker compose up -d
```

Verify the API is reachable:

```bash
PW=$(awk '/user admin/ {print $4}' dev/haproxy/haproxy.cfg)
curl -u admin:$PW http://localhost:5555/v3/info
```

The sample `dev/haproxy/haproxy.cfg` includes a runtime stats socket, which the Data Plane API uses for runtime changes, and a `userlist` for API auth. The `dev/haproxy/dataplaneapi.yml` config enables the API on port 5555 and points to that userlist. The container may regenerate the admin password at startup, so read the current password from `dev/haproxy/haproxy.cfg`.

## Provider Build

```bash
go build ./...
```

## Smoke Tests (Docker)

Run the minimal smoke test against the local Docker environment:

```bash
./scripts/smoke.sh
```

This builds the provider, starts the HAProxy container, applies `examples/smoke/main.tf`, and then destroys it.

## Integration Tests (Docker)

`scripts/registry_integration.sh` and `scripts/registry_runtime_integration.sh` start `docker-compose.integration.yml` (HAProxy with the Data Plane API, Consul, an echo backend), run Terraform in a container on that network with this checkout's provider through `dev_overrides`, check traffic, Consul service discovery, ACME and runtime state, and destroy everything again. Set `PROVIDER_BINARY` to a prebuilt linux/amd64 provider to skip the build (CI does).

CI (`test:integration-docker` in `.gitlab-ci.yml`) runs both against the runner host's Docker daemon, with the images pulled through the Nexus Docker Hub proxy (`scripts/ci-pull-images.sh`). A failure blocks the merge and the release.

## Commits and Releases

Conventional Commits: the next version is derived from them, and every merge to `main` that changes something releases. See `RELEASING.md`.

## Runtime Resources

Runtime resources map to Data Plane API runtime endpoints. If a runtime endpoint uses a path parameter named `id`, the Terraform attribute is named `runtime_id` to avoid colliding with the Terraform `id`.

## OpenAPI Schema Updates

The resource schemas for `backend`, `frontend`, `bind`, and `server` are generated from the Data Plane API OpenAPI spec. See `docs/OPENAPI.md` for the update steps.
