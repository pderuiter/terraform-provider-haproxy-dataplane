locals {
  peer_server_lookup_name = "existing_peer_server"
}

data "haproxy-dataplane_peer_server" "selected" {
}

output "peer_server_id" {
  value = data.haproxy-dataplane_peer_server.selected.id
}
