locals {
  backend_tcp_check_lookup_name = "existing_backend_tcp_check"
}

data "haproxy-dataplane_backend_tcp_check" "selected" {
}

output "backend_tcp_check_id" {
  value = data.haproxy-dataplane_backend_tcp_check.selected.id
}
