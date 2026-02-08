locals {
  acme_lookup_name = "existing_acme"
}

data "haproxy-dataplane_acme" "selected" {
}

output "acme_id" {
  value = data.haproxy-dataplane_acme.selected.id
}
