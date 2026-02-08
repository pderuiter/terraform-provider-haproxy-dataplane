locals {
  default_http_check_lookup_name = "existing_default_http_check"
}

data "haproxy-dataplane_default_http_check" "selected" {
}

output "default_http_check_id" {
  value = data.haproxy-dataplane_default_http_check.selected.id
}
