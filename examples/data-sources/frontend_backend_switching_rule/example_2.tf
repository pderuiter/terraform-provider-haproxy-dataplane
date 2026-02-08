locals {
  frontend_backend_switching_rule_lookup_name = "existing_frontend_backend_switching_rule"
}

data "haproxy-dataplane_frontend_backend_switching_rule" "selected" {
}

output "frontend_backend_switching_rule_id" {
  value = data.haproxy-dataplane_frontend_backend_switching_rule.selected.id
}
