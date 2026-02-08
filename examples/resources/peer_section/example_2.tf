locals {
  peer_section_name = "managed_peer_section"
}

resource "haproxy-dataplane_peer_section" "managed" {
  name = local.peer_section_name

  # Replace with required fields for this object in your environment.
  spec = {}
}

output "peer_section_id" {
  value = haproxy-dataplane_peer_section.managed.id
}
