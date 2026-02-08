locals {
  default_tcp_request_rule_lookup_name = "existing_default_tcp_request_rule"
}

data "haproxy-dataplane_default_tcp_request_rule" "selected" {
}

output "default_tcp_request_rule_id" {
  value = data.haproxy-dataplane_default_tcp_request_rule.selected.id
}
