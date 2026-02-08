locals {
  frontend_http_error_rule_lookup_name = "existing_frontend_http_error_rule"
}

data "haproxy-dataplane_frontend_http_error_rule" "selected" {
}

output "frontend_http_error_rule_id" {
  value = data.haproxy-dataplane_frontend_http_error_rule.selected.id
}
