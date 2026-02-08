locals {
  ring_name = "managed_ring"
}

resource "haproxy-dataplane_ring" "managed" {
  name = local.ring_name

  # Replace with required fields for this object in your environment.
  spec = {}
}

output "ring_id" {
  value = haproxy-dataplane_ring.managed.id
}
