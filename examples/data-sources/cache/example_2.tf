locals {
  cache_lookup_name = "existing_cache"
}

data "haproxy-dataplane_cache" "selected" {
}

output "cache_id" {
  value = data.haproxy-dataplane_cache.selected.id
}
