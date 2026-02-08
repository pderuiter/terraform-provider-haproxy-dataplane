locals {
  frontend_ssl_front_use_lookup_name = "existing_frontend_ssl_front_use"
}

data "haproxy-dataplane_frontend_ssl_front_use" "selected" {
}

output "frontend_ssl_front_use_id" {
  value = data.haproxy-dataplane_frontend_ssl_front_use.selected.id
}
