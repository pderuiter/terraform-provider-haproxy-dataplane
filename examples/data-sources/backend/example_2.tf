locals {
  backend_lookup_name = "existing_backend"
}

data "haproxy-dataplane_backend" "selected" {
}

output "backend_id" {
  value = data.haproxy-dataplane_backend.selected.id
}
