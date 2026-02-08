locals {
  runtime_stick_table_entry_lookup_name = "existing_runtime_stick_table_entry"
}

data "haproxy-dataplane_runtime_stick_table_entry" "selected" {
}

output "runtime_stick_table_entry_id" {
  value = data.haproxy-dataplane_runtime_stick_table_entry.selected.id
}
