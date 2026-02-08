locals {
  backend_server_template_name = "managed_backend_server_template"
}

variable "parent_name" {
  description = "Parent object name, for example a frontend or backend name."
  type        = string
}

variable "prefix" {
  type = string
}

resource "haproxy-dataplane_backend_server_template" "managed" {
  parent_name = var.parent_name
  prefix      = var.prefix

  # Replace with required fields for this object in your environment.
  spec = {}
}

output "backend_server_template_id" {
  value = haproxy-dataplane_backend_server_template.managed.id
}
