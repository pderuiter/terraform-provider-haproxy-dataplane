locals {
  crt_store_name = "managed_crt_store"
}

resource "haproxy-dataplane_crt_store" "managed" {
  name = local.crt_store_name

  # Replace with required fields for this object in your environment.
  spec = {}
}

output "crt_store_id" {
  value = haproxy-dataplane_crt_store.managed.id
}
