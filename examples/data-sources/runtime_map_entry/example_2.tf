locals {
  runtime_map_entry_lookup_name = "existing_runtime_map_entry"
}

data "haproxy-dataplane_runtime_map_entry" "selected" {
}

output "runtime_map_entry_id" {
  value = data.haproxy-dataplane_runtime_map_entry.selected.id
}
