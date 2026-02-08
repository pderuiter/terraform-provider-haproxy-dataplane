locals {
  frontend_tcp_request_rule_lookup_name = "existing_frontend_tcp_request_rule"
}

data "haproxy-dataplane_frontend_tcp_request_rule" "selected" {
}

output "frontend_tcp_request_rule_id" {
  value = data.haproxy-dataplane_frontend_tcp_request_rule.selected.id
}
