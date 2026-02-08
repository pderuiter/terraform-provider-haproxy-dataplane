locals {
  mailers_section_name = "managed_mailers_section"
}

resource "haproxy-dataplane_mailers_section" "managed" {
  name = local.mailers_section_name

  # Replace with required fields for this object in your environment.
  spec = {}
}

output "mailers_section_id" {
  value = haproxy-dataplane_mailers_section.managed.id
}
