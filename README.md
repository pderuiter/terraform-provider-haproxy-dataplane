# Terraform Provider: HAProxy Data Plane API

This provider manages HAProxy configuration via the HAProxy Data Plane API.

## Status

This is an initial implementation focused on core configuration resources. The next iterations will expand coverage to all Data Plane API configuration objects and add data sources and acceptance tests. The provider is designed to be extended using the Data Plane API specification.

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
    balance = "roundrobin"
  }
}

resource "haproxy-dataplane_frontend" "app" {
  name = "fe_app"
  spec = {
    mode            = "http"
    default_backend = "be_app"
  }
}

resource "haproxy-dataplane_bind" "app" {
  frontend = haproxy-dataplane_frontend.app.name
  name     = "app"
  spec = {
    address = "*"
    port    = 8080
  }
}

resource "haproxy-dataplane_server" "s1" {
  backend = haproxy-dataplane_backend.app.name
  name    = "s1"
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

## Notes

- `spec` matches the object shape expected by the Data Plane API endpoint.
- The provider automatically fetches the configuration version before applying changes.

## Roadmap (Next Iterations)

- Expand resource coverage to all Data Plane API configuration objects.
- Add data sources for read-only use cases.
- Add acceptance tests (docker-based) and CI.
- Add code generation pipeline from OpenAPI specification.
