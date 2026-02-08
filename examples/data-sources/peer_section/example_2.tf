locals {
  peer_section_lookup_name = "existing_peer_section"
}

data "haproxy-dataplane_peer_section" "selected" {
}

output "peer_section_id" {
  value = data.haproxy-dataplane_peer_section.selected.id
}
