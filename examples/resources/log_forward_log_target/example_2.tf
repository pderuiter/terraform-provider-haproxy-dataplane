locals {
  log_forward_log_target_name = "managed_log_forward_log_target"
}

variable "parent_name" {
  description = "Parent object name, for example a frontend or backend name."
  type        = string
}

resource "haproxy-dataplane_log_forward_log_target" "managed" {
  parent_name = var.parent_name

  # Replace with required fields for this object in your environment.
  spec = {}
}

output "log_forward_log_target_id" {
  value = haproxy-dataplane_log_forward_log_target.managed.id
}
