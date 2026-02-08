locals {
  runtime_stick_table_lookup_name = "existing_runtime_stick_table"
}

data "haproxy-dataplane_runtime_stick_table" "selected" {
}

output "runtime_stick_table_id" {
  value = data.haproxy-dataplane_runtime_stick_table.selected.id
}
