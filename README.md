# Terraform Provider: HAProxy Data Plane API

This provider manages HAProxy configuration via the HAProxy Data Plane API.

## Status

This provider is generated from the HAProxy Data Plane API OpenAPI spec and includes configuration resources, runtime resources, and data sources. The runtime coverage targets the Data Plane API runtime endpoints.

## Requirements

- Go 1.24+
- Terraform 1.5+
- Docker (for local testing)
- HAProxy Data Plane API (v3 path by default)

## Quick Start (Local)

1. Start HAProxy with the official Docker image (includes the Data Plane API):

```bash
docker compose up -d
```

2. Initialize Terraform with the provider:

```hcl
terraform {
  required_providers {
    haproxy-dataplane = {
      source  = "pderuiter/haproxy-dataplane"
      version = "0.1.0"
    }
  }
}

provider "haproxy-dataplane" {
  endpoint = "http://localhost:5555"
  username = "admin"
  password = var.haproxy_admin_password
  api_path = "/v3"
}
```

When using the provided docker setup, the admin password is generated at startup and stored in `dev/haproxy/haproxy.cfg` under the `userlist controller` section.

3. Example resources:

```hcl
resource "haproxy-dataplane_backend" "app" {
  name = "be_app"
  spec = {
    mode    = "http"
    balance = {
      algorithm = "roundrobin"
    }
  }
}

resource "haproxy-dataplane_frontend" "app" {
  name = "fe_app"
  spec = {
    mode            = "http"
    default_backend = "be_app"
  }
}

resource "haproxy-dataplane_frontend_bind" "app" {
  parent_name = haproxy-dataplane_frontend.app.name
  name        = "app"
  spec = {
    address = "*"
    port    = 8080
  }
}

resource "haproxy-dataplane_backend_server" "s1" {
  parent_name = haproxy-dataplane_backend.app.name
  name        = "s1"
  spec = {
    address = "127.0.0.1"
    port    = 9000
  }
}
```

## Local Development

- Build:

```bash
go build ./...
```

- Lint and test:

```bash
go test ./...
```

## Runtime Resources

Runtime resources map to Data Plane API runtime endpoints. If a runtime endpoint uses a path parameter named `id`, the Terraform attribute is named `runtime_id` to avoid colliding with the Terraform `id`.

Examples:
- `haproxy-dataplane_runtime_map`
- `haproxy-dataplane_runtime_map_entry` (uses `runtime_id`)
- `haproxy-dataplane_runtime_acl_entry` (uses `runtime_id`)
- `haproxy-dataplane_runtime_backend_server`

## Smoke Tests (Docker)

Run the local smoke test with Docker and a local provider build:

```bash
./scripts/smoke.sh
```

## Notes

- `spec` matches the object shape expected by the Data Plane API endpoint.
- The provider automatically fetches the configuration version before applying changes.
- Runtime resources use `runtime_id` when the API path parameter is named `id`.

## Roadmap (Next Iterations)

- Harden runtime coverage and acceptance tests.
- Improve registry documentation and examples.
- Expand CI coverage.
