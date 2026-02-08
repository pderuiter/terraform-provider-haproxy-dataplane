locals {
  default_http_error_rule_lookup_name = "existing_default_http_error_rule"
}

data "haproxy-dataplane_default_http_error_rule" "selected" {
}

output "default_http_error_rule_id" {
  value = data.haproxy-dataplane_default_http_error_rule.selected.id
}
