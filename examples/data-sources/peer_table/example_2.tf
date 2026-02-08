locals {
  peer_table_lookup_name = "existing_peer_table"
}

data "haproxy-dataplane_peer_table" "selected" {
}

output "peer_table_id" {
  value = data.haproxy-dataplane_peer_table.selected.id
}
