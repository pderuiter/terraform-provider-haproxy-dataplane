locals {
  frontend_filter_name = "managed_frontend_filter"
}

variable "parent_name" {
  description = "Parent object name, for example a frontend or backend name."
  type        = string
}

resource "haproxy-dataplane_frontend_filter" "managed" {
  parent_name = var.parent_name

  # Replace with required fields for this object in your environment.
  spec = {}
}

output "frontend_filter_id" {
  value = haproxy-dataplane_frontend_filter.managed.id
}
