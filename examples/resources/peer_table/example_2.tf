locals {
  peer_table_name = "managed_peer_table"
}

variable "parent_name" {
  description = "Parent object name, for example a frontend or backend name."
  type        = string
}

resource "haproxy-dataplane_peer_table" "managed" {
  name        = local.peer_table_name
  parent_name = var.parent_name

  # Replace with required fields for this object in your environment.
  spec = {}
}

output "peer_table_id" {
  value = haproxy-dataplane_peer_table.managed.id
}
