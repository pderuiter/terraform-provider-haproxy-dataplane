locals {
  runtime_ssl_ca_file_lookup_name = "existing_runtime_ssl_ca_file"
}

data "haproxy-dataplane_runtime_ssl_ca_file" "selected" {
}

output "runtime_ssl_ca_file_id" {
  value = data.haproxy-dataplane_runtime_ssl_ca_file.selected.id
}
