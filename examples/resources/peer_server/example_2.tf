locals {
  peer_server_name = "managed_peer_server"
}

variable "parent_name" {
  description = "Parent object name, for example a frontend or backend name."
  type        = string
}

resource "haproxy-dataplane_peer_server" "managed" {
  name        = local.peer_server_name
  parent_name = var.parent_name

  # Replace with required fields for this object in your environment.
  spec = {}
}

output "peer_server_id" {
  value = haproxy-dataplane_peer_server.managed.id
}
