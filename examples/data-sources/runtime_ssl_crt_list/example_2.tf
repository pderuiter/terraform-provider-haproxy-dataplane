locals {
  runtime_ssl_crt_list_lookup_name = "existing_runtime_ssl_crt_list"
}

data "haproxy-dataplane_runtime_ssl_crt_list" "selected" {
}

output "runtime_ssl_crt_list_id" {
  value = data.haproxy-dataplane_runtime_ssl_crt_list.selected.id
}
