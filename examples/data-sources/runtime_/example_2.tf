locals {
  runtime__lookup_name = "existing_runtime_"
}

data "haproxy-dataplane_runtime_" "selected" {
}

output "runtime__id" {
  value = data.haproxy-dataplane_runtime_.selected.id
}
