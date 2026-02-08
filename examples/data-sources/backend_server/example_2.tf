locals {
  backend_server_lookup_name = "existing_backend_server"
}

data "haproxy-dataplane_backend_server" "selected" {
}

output "backend_server_id" {
  value = data.haproxy-dataplane_backend_server.selected.id
}
