locals {
  ring_server_name = "managed_ring_server"
}

variable "parent_name" {
  description = "Parent object name, for example a frontend or backend name."
  type        = string
}

resource "haproxy-dataplane_ring_server" "managed" {
  name        = local.ring_server_name
  parent_name = var.parent_name

  # Replace with required fields for this object in your environment.
  spec = {}
}

output "ring_server_id" {
  value = haproxy-dataplane_ring_server.managed.id
}
