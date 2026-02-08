locals {
  backend_http_request_rule_lookup_name = "existing_backend_http_request_rule"
}

data "haproxy-dataplane_backend_http_request_rule" "selected" {
}

output "backend_http_request_rule_id" {
  value = data.haproxy-dataplane_backend_http_request_rule.selected.id
}
