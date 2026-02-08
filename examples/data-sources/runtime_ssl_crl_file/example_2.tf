locals {
  runtime_ssl_crl_file_lookup_name = "existing_runtime_ssl_crl_file"
}

data "haproxy-dataplane_runtime_ssl_crl_file" "selected" {
}

output "runtime_ssl_crl_file_id" {
  value = data.haproxy-dataplane_runtime_ssl_crl_file.selected.id
}
