locals {
  runtime_backend_server_name = "managed_runtime_backend_server"
}

variable "parent_name" {
  description = "Parent object name, for example a frontend or backend name."
  type        = string
}

resource "haproxy-dataplane_runtime_backend_server" "managed" {
  name        = local.runtime_backend_server_name
  parent_name = var.parent_name

  # Replace with required fields for this object in your environment.
  spec = {}
}

output "runtime_backend_server_id" {
  value = haproxy-dataplane_runtime_backend_server.managed.id
}
