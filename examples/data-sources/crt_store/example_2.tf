locals {
  crt_store_lookup_name = "existing_crt_store"
}

data "haproxy-dataplane_crt_store" "selected" {
}

output "crt_store_id" {
  value = data.haproxy-dataplane_crt_store.selected.id
}
