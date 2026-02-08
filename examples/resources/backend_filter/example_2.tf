locals {
  backend_filter_name = "managed_backend_filter"
}

variable "parent_name" {
  description = "Parent object name, for example a frontend or backend name."
  type        = string
}

resource "haproxy-dataplane_backend_filter" "managed" {
  parent_name = var.parent_name

  # Replace with required fields for this object in your environment.
  spec = {}
}

output "backend_filter_id" {
  value = haproxy-dataplane_backend_filter.managed.id
}
