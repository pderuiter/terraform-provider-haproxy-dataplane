locals {
  runtime_ssl_ca_file_entry_lookup_name = "existing_runtime_ssl_ca_file_entry"
}

variable "index" {
  type = string
}

data "haproxy-dataplane_runtime_ssl_ca_file_entry" "selected" {
  index = var.index
  name  = local.runtime_ssl_ca_file_entry_name
}

output "runtime_ssl_ca_file_entry_id" {
  value = data.haproxy-dataplane_runtime_ssl_ca_file_entry.selected.id
}
