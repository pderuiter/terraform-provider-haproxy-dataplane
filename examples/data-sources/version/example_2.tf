locals {
  version_lookup_name = "existing_version"
}

data "haproxy-dataplane_version" "selected" {
}

output "version_id" {
  value = data.haproxy-dataplane_version.selected.id
}
