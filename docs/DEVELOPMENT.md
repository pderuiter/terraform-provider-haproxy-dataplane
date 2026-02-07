# Development

## Local HAProxy + Data Plane API

The official HAProxy Docker images include the Data Plane API. This repository ships a minimal `docker-compose.yml` with sample configs in `dev/`.

```bash
docker compose up -d
```

Verify the API is reachable:

```bash
curl -u admin:adminpwd http://localhost:5555/v3/info
```

The sample `dev/haproxy.cfg` includes a runtime stats socket, which the Data Plane API uses for runtime changes, and a `userlist` for API auth. The `dev/dataplaneapi.yml` config enables the API on port 5555 and points to that userlist.

## Provider Build

```bash
go build ./...
```

## Provider Acceptance Tests (Planned)

Acceptance tests will run against the dockerized HAProxy instance and apply Terraform configurations to verify CRUD for each resource.
