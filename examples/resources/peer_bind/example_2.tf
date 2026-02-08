locals {
  peer_bind_name = "managed_peer_bind"
}

variable "parent_name" {
  description = "Parent object name, for example a frontend or backend name."
  type        = string
}

resource "haproxy-dataplane_peer_bind" "managed" {
  name        = local.peer_bind_name
  parent_name = var.parent_name

  # Replace with required fields for this object in your environment.
  spec = {}
}

output "peer_bind_id" {
  value = haproxy-dataplane_peer_bind.managed.id
}
