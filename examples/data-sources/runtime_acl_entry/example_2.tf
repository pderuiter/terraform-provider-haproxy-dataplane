locals {
  runtime_acl_entry_lookup_name = "existing_runtime_acl_entry"
}

data "haproxy-dataplane_runtime_acl_entry" "selected" {
}

output "runtime_acl_entry_id" {
  value = data.haproxy-dataplane_runtime_acl_entry.selected.id
}
