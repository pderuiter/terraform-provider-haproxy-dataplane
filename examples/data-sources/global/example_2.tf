locals {
  global_lookup_name = "existing_global"
}

data "haproxy-dataplane_global" "selected" {
}

output "global_id" {
  value = data.haproxy-dataplane_global.selected.id
}
