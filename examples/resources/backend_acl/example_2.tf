locals {
  backend_acl_name = "managed_backend_acl"
}

variable "parent_name" {
  description = "Parent object name, for example a frontend or backend name."
  type        = string
}

resource "haproxy-dataplane_backend_acl" "managed" {
  parent_name = var.parent_name

  # Replace with required fields for this object in your environment.
  spec = {}
}

output "backend_acl_id" {
  value = haproxy-dataplane_backend_acl.managed.id
}
