locals {
  runtime_ssl_crt_list_entry_lookup_name = "existing_runtime_ssl_crt_list_entry"
}

data "haproxy-dataplane_runtime_ssl_crt_list_entry" "selected" {
  name = local.runtime_ssl_crt_list_entry_name
}

output "runtime_ssl_crt_list_entry_id" {
  value = data.haproxy-dataplane_runtime_ssl_crt_list_entry.selected.id
}
