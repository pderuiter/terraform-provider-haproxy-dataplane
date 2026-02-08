locals {
  runtime_ssl_cert_lookup_name = "existing_runtime_ssl_cert"
}

data "haproxy-dataplane_runtime_ssl_cert" "selected" {
}

output "runtime_ssl_cert_id" {
  value = data.haproxy-dataplane_runtime_ssl_cert.selected.id
}
