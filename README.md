# Terraform Provider: HAProxy Data Plane API

This provider manages HAProxy configuration via the HAProxy Data Plane API.

## Status

This is an initial implementation focused on core configuration resources. The next iterations will expand coverage to all Data Plane API configuration objects and add data sources and acceptance tests. The provider is designed to be extended using the Data Plane API specification.

## Requirements

- Go 1.22+
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
  password = "adminpwd"
  api_path = "/v3"
}
```

3. Example resources:

```hcl
resource "haproxy-dataplane_backend" "app" {
  name = "be_app"
  config_json = jsonencode({
    mode = "http"
    balance = "roundrobin"
  })
}

resource "haproxy-dataplane_frontend" "app" {
  name = "fe_app"
  config_json = jsonencode({
    mode = "http"
    bind = "*:8080"
    default_backend = "be_app"
  })
}

resource "haproxy-dataplane_server" "s1" {
  backend = haproxy-dataplane_backend.app.name
  name    = "s1"
  config_json = jsonencode({
    address = "127.0.0.1"
    port    = 9000
    check   = "enabled"
  })
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

- `config_json` should match the object shape expected by the Data Plane API endpoint.
- The provider automatically fetches the configuration version before applying changes.

## Roadmap (Next Iterations)

- Expand resource coverage to all Data Plane API configuration objects.
- Add data sources for read-only use cases.
- Add acceptance tests (docker-based) and CI.
- Add code generation pipeline from OpenAPI specification.
