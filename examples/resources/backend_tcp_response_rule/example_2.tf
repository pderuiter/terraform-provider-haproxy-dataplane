locals {
  backend_tcp_response_rule_name = "managed_backend_tcp_response_rule"
}

variable "parent_name" {
  description = "Parent object name, for example a frontend or backend name."
  type        = string
}

resource "haproxy-dataplane_backend_tcp_response_rule" "managed" {
  parent_name = var.parent_name

  # Replace with required fields for this object in your environment.
  spec = {}
}

output "backend_tcp_response_rule_id" {
  value = haproxy-dataplane_backend_tcp_response_rule.managed.id
}
