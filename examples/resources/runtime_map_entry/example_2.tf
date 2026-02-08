locals {
  runtime_map_entry_name = "managed_runtime_map_entry"
}

variable "parent_name" {
  description = "Parent object name, for example a frontend or backend name."
  type        = string
}

variable "runtime_id" {
  description = "Runtime API object id, if required by this endpoint."
  type        = string
}

resource "haproxy-dataplane_runtime_map_entry" "managed" {
  parent_name = var.parent_name
  runtime_id  = var.runtime_id

  # Replace with required fields for this object in your environment.
  spec = {}
}

output "runtime_map_entry_id" {
  value = haproxy-dataplane_runtime_map_entry.managed.id
}
