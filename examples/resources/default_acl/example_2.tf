locals {
  default_acl_name = "managed_default_acl"
}

variable "parent_name" {
  description = "Parent object name, for example a frontend or backend name."
  type        = string
}

resource "haproxy-dataplane_default_acl" "managed" {
  parent_name = var.parent_name

  # Replace with required fields for this object in your environment.
  spec = {}
}

output "default_acl_id" {
  value = haproxy-dataplane_default_acl.managed.id
}
