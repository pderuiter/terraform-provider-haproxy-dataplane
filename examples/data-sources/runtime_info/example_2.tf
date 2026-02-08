locals {
  runtime_info_lookup_name = "existing_runtime_info"
}

data "haproxy-dataplane_runtime_info" "selected" {
}

output "runtime_info_id" {
  value = data.haproxy-dataplane_runtime_info.selected.id
}
