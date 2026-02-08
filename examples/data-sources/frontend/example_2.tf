locals {
  frontend_lookup_name = "existing_frontend"
}

data "haproxy-dataplane_frontend" "selected" {
}

output "frontend_id" {
  value = data.haproxy-dataplane_frontend.selected.id
}
