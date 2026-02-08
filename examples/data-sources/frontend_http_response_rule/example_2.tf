locals {
  frontend_http_response_rule_lookup_name = "existing_frontend_http_response_rule"
}

data "haproxy-dataplane_frontend_http_response_rule" "selected" {
}

output "frontend_http_response_rule_id" {
  value = data.haproxy-dataplane_frontend_http_response_rule.selected.id
}
