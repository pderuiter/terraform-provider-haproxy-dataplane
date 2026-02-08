locals {
  peer_bind_lookup_name = "existing_peer_bind"
}

data "haproxy-dataplane_peer_bind" "selected" {
}

output "peer_bind_id" {
  value = data.haproxy-dataplane_peer_bind.selected.id
}
