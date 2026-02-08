locals {
  cache_name = "managed_cache"
}

resource "haproxy-dataplane_cache" "managed" {
  name = local.cache_name

  # Replace with required fields for this object in your environment.
  spec = {}
}

output "cache_id" {
  value = haproxy-dataplane_cache.managed.id
}
