locals {
  runtime_map_lookup_name = "existing_runtime_map"
}

data "haproxy-dataplane_runtime_map" "selected" {
}

output "runtime_map_id" {
  value = data.haproxy-dataplane_runtime_map.selected.id
}
