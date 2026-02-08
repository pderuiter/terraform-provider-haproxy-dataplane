locals {
  frontend_ssl_front_use_name = "managed_frontend_ssl_front_use"
}

variable "parent_name" {
  description = "Parent object name, for example a frontend or backend name."
  type        = string
}

variable "index" {
  type = string
}

resource "haproxy-dataplane_frontend_ssl_front_use" "managed" {
  index       = var.index
  parent_name = var.parent_name

  # Replace with required fields for this object in your environment.
  spec = {}
}

output "frontend_ssl_front_use_id" {
  value = haproxy-dataplane_frontend_ssl_front_use.managed.id
}
