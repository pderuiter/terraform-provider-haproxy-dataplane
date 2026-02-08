locals {
  peer_entry_name = "managed_peer_entry"
}

variable "peer_section" {
  type = string
}

resource "haproxy-dataplane_peer_entry" "managed" {
  name         = local.peer_entry_name
  peer_section = var.peer_section

  # Replace with required fields for this object in your environment.
  spec = {}
}

output "peer_entry_id" {
  value = haproxy-dataplane_peer_entry.managed.id
}
