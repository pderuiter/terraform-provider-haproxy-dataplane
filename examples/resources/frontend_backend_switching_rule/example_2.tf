locals {
  frontend_backend_switching_rule_name = "managed_frontend_backend_switching_rule"
}

variable "parent_name" {
  description = "Parent object name, for example a frontend or backend name."
  type        = string
}

resource "haproxy-dataplane_frontend_backend_switching_rule" "managed" {
  parent_name = var.parent_name

  # Replace with required fields for this object in your environment.
  spec = {}
}

output "frontend_backend_switching_rule_id" {
  value = haproxy-dataplane_frontend_backend_switching_rule.managed.id
}
