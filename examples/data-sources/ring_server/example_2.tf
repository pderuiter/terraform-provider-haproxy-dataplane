locals {
  ring_server_lookup_name = "existing_ring_server"
}

data "haproxy-dataplane_ring_server" "selected" {
}

output "ring_server_id" {
  value = data.haproxy-dataplane_ring_server.selected.id
}
