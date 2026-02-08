locals {
  backend_filter_lookup_name = "existing_backend_filter"
}

data "haproxy-dataplane_backend_filter" "selected" {
}

output "backend_filter_id" {
  value = data.haproxy-dataplane_backend_filter.selected.id
}
