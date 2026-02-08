locals {
  default_lookup_name = "existing_default"
}

data "haproxy-dataplane_default" "selected" {
}

output "default_id" {
  value = data.haproxy-dataplane_default.selected.id
}
