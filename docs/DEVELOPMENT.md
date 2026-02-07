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

## Provider Acceptance Tests (Planned)

Acceptance tests will run against the dockerized HAProxy instance and apply Terraform configurations to verify CRUD for each resource.

## OpenAPI Schema Updates

The resource schemas for `backend`, `frontend`, `bind`, and `server` are generated from the Data Plane API OpenAPI spec. See `docs/OPENAPI.md` for the update steps.
