locals {
  frontend_acl_lookup_name = "existing_frontend_acl"
}

data "haproxy-dataplane_frontend_acl" "selected" {
}

output "frontend_acl_id" {
  value = data.haproxy-dataplane_frontend_acl.selected.id
}
