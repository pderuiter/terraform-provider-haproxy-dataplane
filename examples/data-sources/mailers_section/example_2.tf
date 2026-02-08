locals {
  mailers_section_lookup_name = "existing_mailers_section"
}

data "haproxy-dataplane_mailers_section" "selected" {
}

output "mailers_section_id" {
  value = data.haproxy-dataplane_mailers_section.selected.id
}
