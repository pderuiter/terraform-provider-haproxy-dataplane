locals {
  ring_lookup_name = "existing_ring"
}

data "haproxy-dataplane_ring" "selected" {
}

output "ring_id" {
  value = data.haproxy-dataplane_ring.selected.id
}
