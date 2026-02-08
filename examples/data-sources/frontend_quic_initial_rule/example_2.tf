locals {
  frontend_quic_initial_rule_lookup_name = "existing_frontend_quic_initial_rule"
}

data "haproxy-dataplane_frontend_quic_initial_rule" "selected" {
}

output "frontend_quic_initial_rule_id" {
  value = data.haproxy-dataplane_frontend_quic_initial_rule.selected.id
}
