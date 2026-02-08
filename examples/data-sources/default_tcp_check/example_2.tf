locals {
  default_tcp_check_lookup_name = "existing_default_tcp_check"
}

data "haproxy-dataplane_default_tcp_check" "selected" {
}

output "default_tcp_check_id" {
  value = data.haproxy-dataplane_default_tcp_check.selected.id
}
