locals {
  backend_server_switching_rule_lookup_name = "existing_backend_server_switching_rule"
}

data "haproxy-dataplane_backend_server_switching_rule" "selected" {
}

output "backend_server_switching_rule_id" {
  value = data.haproxy-dataplane_backend_server_switching_rule.selected.id
}
