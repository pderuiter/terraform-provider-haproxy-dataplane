locals {
  runtime_map_name = "managed_runtime_map"
}

resource "haproxy-dataplane_runtime_map" "managed" {
  name = local.runtime_map_name

  # Replace with required fields for this object in your environment.
  spec = {}
}

output "runtime_map_id" {
  value = haproxy-dataplane_runtime_map.managed.id
}
