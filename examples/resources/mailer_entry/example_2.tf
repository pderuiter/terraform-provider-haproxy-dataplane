locals {
  mailer_entry_name = "managed_mailer_entry"
}

variable "mailers_section" {
  type = string
}

resource "haproxy-dataplane_mailer_entry" "managed" {
  mailers_section = var.mailers_section
  name            = local.mailer_entry_name

  # Replace with required fields for this object in your environment.
  spec = {}
}

output "mailer_entry_id" {
  value = haproxy-dataplane_mailer_entry.managed.id
}
