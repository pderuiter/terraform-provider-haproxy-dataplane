locals {
  default_http_request_rule_lookup_name = "existing_default_http_request_rule"
}

data "haproxy-dataplane_default_http_request_rule" "selected" {
}

output "default_http_request_rule_id" {
  value = data.haproxy-dataplane_default_http_request_rule.selected.id
}
