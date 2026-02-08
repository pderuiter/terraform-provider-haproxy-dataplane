locals {
  frontend_bind_lookup_name = "existing_frontend_bind"
}

data "haproxy-dataplane_frontend_bind" "selected" {
}

output "frontend_bind_id" {
  value = data.haproxy-dataplane_frontend_bind.selected.id
}
