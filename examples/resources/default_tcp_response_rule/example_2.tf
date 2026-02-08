locals {
  default_tcp_response_rule_name = "managed_default_tcp_response_rule"
}

variable "parent_name" {
  description = "Parent object name, for example a frontend or backend name."
  type        = string
}

resource "haproxy-dataplane_default_tcp_response_rule" "managed" {
  parent_name = var.parent_name

  # Replace with required fields for this object in your environment.
  spec = {}
}

output "default_tcp_response_rule_id" {
  value = haproxy-dataplane_default_tcp_response_rule.managed.id
}
