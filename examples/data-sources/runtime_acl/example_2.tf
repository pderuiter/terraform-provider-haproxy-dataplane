locals {
  runtime_acl_lookup_name = "existing_runtime_acl"
}

data "haproxy-dataplane_runtime_acl" "selected" {
}

output "runtime_acl_id" {
  value = data.haproxy-dataplane_runtime_acl.selected.id
}
