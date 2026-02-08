locals {
  backend_acl_lookup_name = "existing_backend_acl"
}

data "haproxy-dataplane_backend_acl" "selected" {
}

output "backend_acl_id" {
  value = data.haproxy-dataplane_backend_acl.selected.id
}
