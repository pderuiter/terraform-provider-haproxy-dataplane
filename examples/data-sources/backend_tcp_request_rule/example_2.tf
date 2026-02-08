locals {
  backend_tcp_request_rule_lookup_name = "existing_backend_tcp_request_rule"
}

data "haproxy-dataplane_backend_tcp_request_rule" "selected" {
}

output "backend_tcp_request_rule_id" {
  value = data.haproxy-dataplane_backend_tcp_request_rule.selected.id
}
