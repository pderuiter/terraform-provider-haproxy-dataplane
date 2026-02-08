locals {
  runtime_backend_server_lookup_name = "existing_runtime_backend_server"
}

data "haproxy-dataplane_runtime_backend_server" "selected" {
}

output "runtime_backend_server_id" {
  value = data.haproxy-dataplane_runtime_backend_server.selected.id
}
