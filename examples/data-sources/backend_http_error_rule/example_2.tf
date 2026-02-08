locals {
  backend_http_error_rule_lookup_name = "existing_backend_http_error_rule"
}

data "haproxy-dataplane_backend_http_error_rule" "selected" {
}

output "backend_http_error_rule_id" {
  value = data.haproxy-dataplane_backend_http_error_rule.selected.id
}
