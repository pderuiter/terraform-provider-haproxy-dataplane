locals {
  runtime_acl_entry_name = "managed_runtime_acl_entry"
}

variable "parent_name" {
  description = "Parent object name, for example a frontend or backend name."
  type        = string
}

resource "haproxy-dataplane_runtime_acl_entry" "managed" {
  parent_name = var.parent_name

  # Replace with required fields for this object in your environment.
  spec = {}
}

output "runtime_acl_entry_id" {
  value = haproxy-dataplane_runtime_acl_entry.managed.id
}
