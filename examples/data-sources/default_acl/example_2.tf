locals {
  default_acl_lookup_name = "existing_default_acl"
}

data "haproxy-dataplane_default_acl" "selected" {
}

output "default_acl_id" {
  value = data.haproxy-dataplane_default_acl.selected.id
}
