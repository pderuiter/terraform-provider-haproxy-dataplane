locals {
  backend_log_target_name = "managed_backend_log_target"
}

variable "parent_name" {
  description = "Parent object name, for example a frontend or backend name."
  type        = string
}

resource "haproxy-dataplane_backend_log_target" "managed" {
  parent_name = var.parent_name

  # Replace with required fields for this object in your environment.
  spec = {}
}

output "backend_log_target_id" {
  value = haproxy-dataplane_backend_log_target.managed.id
}
