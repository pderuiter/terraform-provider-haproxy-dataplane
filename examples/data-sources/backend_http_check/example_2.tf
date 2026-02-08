locals {
  backend_http_check_lookup_name = "existing_backend_http_check"
}

data "haproxy-dataplane_backend_http_check" "selected" {
}

output "backend_http_check_id" {
  value = data.haproxy-dataplane_backend_http_check.selected.id
}
