locals {
  mailer_entry_lookup_name = "existing_mailer_entry"
}

variable "mailers_section" {
  type = string
}

data "haproxy-dataplane_mailer_entry" "selected" {
  mailers_section = var.mailers_section
}

output "mailer_entry_id" {
  value = data.haproxy-dataplane_mailer_entry.selected.id
}
