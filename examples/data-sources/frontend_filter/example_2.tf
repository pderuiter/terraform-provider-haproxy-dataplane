locals {
  frontend_filter_lookup_name = "existing_frontend_filter"
}

data "haproxy-dataplane_frontend_filter" "selected" {
}

output "frontend_filter_id" {
  value = data.haproxy-dataplane_frontend_filter.selected.id
}
