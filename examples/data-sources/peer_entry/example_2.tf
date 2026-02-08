locals {
  peer_entry_lookup_name = "existing_peer_entry"
}

variable "peer_section" {
  type = string
}

data "haproxy-dataplane_peer_entry" "selected" {
  peer_section = var.peer_section
}

output "peer_entry_id" {
  value = data.haproxy-dataplane_peer_entry.selected.id
}
