locals {
  default_tcp_response_rule_lookup_name = "existing_default_tcp_response_rule"
}

data "haproxy-dataplane_default_tcp_response_rule" "selected" {
}

output "default_tcp_response_rule_id" {
  value = data.haproxy-dataplane_default_tcp_response_rule.selected.id
}
