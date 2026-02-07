# OpenAPI Code Generation

The provider schema for core resources is generated from the HAProxy Data Plane API OpenAPI specification.

## Fetch the Spec

```bash
PW=$(awk '/user admin/ {print $4}' dev/haproxy/haproxy.cfg)
curl -u admin:$PW http://localhost:5555/v3/specification_openapiv3 -o spec/openapi.json
```

## Generate Provider Schema

```bash
go run ./scripts/gen_schema
```

This regenerates:

- `internal/provider/gen_backend_spec.go`
- `internal/provider/gen_frontend_spec.go`
- `internal/provider/gen_bind_spec.go`
- `internal/provider/gen_server_spec.go`
- `internal/provider/gen_schema_registry.go`

## Generate Resources

```bash
python3 scripts/gen_resources.py
```

This regenerates resource definitions under `internal/provider/gen_resource_*.go` and updates `internal/provider/resources_gen.go`.

The generator includes configuration endpoints that support `POST` (collection create) or `PUT` (item update/create). For endpoints that only support `GET`, add data sources as needed.

## Generate Data Sources

```bash
python3 scripts/gen_datasources.py
```

This regenerates `internal/provider/gen_data_source_*.go` and updates `internal/provider/datasources_gen.go`.
