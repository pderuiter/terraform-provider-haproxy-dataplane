locals {
  backend_stick_rule_lookup_name = "existing_backend_stick_rule"
}

data "haproxy-dataplane_backend_stick_rule" "selected" {
}

output "backend_stick_rule_id" {
  value = data.haproxy-dataplane_backend_stick_rule.selected.id
}
