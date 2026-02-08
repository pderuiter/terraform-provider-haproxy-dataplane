locals {
  global_log_target_name = "managed_global_log_target"
}

variable "index" {
  type = string
}

resource "haproxy-dataplane_global_log_target" "managed" {
  index = var.index

  # Replace with required fields for this object in your environment.
  spec = {}
}

output "global_log_target_id" {
  value = haproxy-dataplane_global_log_target.managed.id
}
