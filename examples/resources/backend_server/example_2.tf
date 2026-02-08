locals {
  backend_server_name = "managed_backend_server"
}

variable "parent_name" {
  description = "Parent object name, for example a frontend or backend name."
  type        = string
}

resource "haproxy-dataplane_backend_server" "managed" {
  name        = local.backend_server_name
  parent_name = var.parent_name

  # Replace with required fields for this object in your environment.
  spec = {}
}

output "backend_server_id" {
  value = haproxy-dataplane_backend_server.managed.id
}
