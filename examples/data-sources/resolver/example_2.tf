locals {
  resolver_lookup_name = "existing_resolver"
}

data "haproxy-dataplane_resolver" "selected" {
}

output "resolver_id" {
  value = data.haproxy-dataplane_resolver.selected.id
}
