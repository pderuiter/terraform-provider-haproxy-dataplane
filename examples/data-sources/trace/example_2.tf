locals {
  trace_lookup_name = "existing_trace"
}

data "haproxy-dataplane_trace" "selected" {
}

output "trace_id" {
  value = data.haproxy-dataplane_trace.selected.id
}
