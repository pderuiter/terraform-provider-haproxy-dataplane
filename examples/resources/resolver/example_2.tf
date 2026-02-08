locals {
  resolver_name = "managed_resolver"
}

resource "haproxy-dataplane_resolver" "managed" {
  name = local.resolver_name

  # Replace with required fields for this object in your environment.
  spec = {}
}

output "resolver_id" {
  value = haproxy-dataplane_resolver.managed.id
}
