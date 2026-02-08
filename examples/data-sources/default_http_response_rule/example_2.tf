locals {
  default_http_response_rule_lookup_name = "existing_default_http_response_rule"
}

data "haproxy-dataplane_default_http_response_rule" "selected" {
}

output "default_http_response_rule_id" {
  value = data.haproxy-dataplane_default_http_response_rule.selected.id
}
