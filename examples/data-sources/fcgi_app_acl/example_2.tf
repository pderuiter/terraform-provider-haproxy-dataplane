locals {
  fcgi_app_acl_lookup_name = "existing_fcgi_app_acl"
}

data "haproxy-dataplane_fcgi_app_acl" "selected" {
}

output "fcgi_app_acl_id" {
  value = data.haproxy-dataplane_fcgi_app_acl.selected.id
}
