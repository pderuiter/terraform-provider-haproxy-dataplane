locals {
  default_quic_initial_rule_lookup_name = "existing_default_quic_initial_rule"
}

data "haproxy-dataplane_default_quic_initial_rule" "selected" {
}

output "default_quic_initial_rule_id" {
  value = data.haproxy-dataplane_default_quic_initial_rule.selected.id
}
