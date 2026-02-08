locals {
  runtime_acme_lookup_name = "existing_runtime_acme"
}

data "haproxy-dataplane_runtime_acme" "selected" {
}

output "runtime_acme_id" {
  value = data.haproxy-dataplane_runtime_acme.selected.id
}
