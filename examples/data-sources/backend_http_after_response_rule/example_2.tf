locals {
  backend_http_after_response_rule_lookup_name = "existing_backend_http_after_response_rule"
}

data "haproxy-dataplane_backend_http_after_response_rule" "selected" {
}

output "backend_http_after_response_rule_id" {
  value = data.haproxy-dataplane_backend_http_after_response_rule.selected.id
}
