locals {
  program_lookup_name = "existing_program"
}

data "haproxy-dataplane_program" "selected" {
}

output "program_id" {
  value = data.haproxy-dataplane_program.selected.id
}
