locals {
  program_name = "managed_program"
}

resource "haproxy-dataplane_program" "managed" {
  name = local.program_name

  # Replace with required fields for this object in your environment.
  spec = {}
}

output "program_id" {
  value = haproxy-dataplane_program.managed.id
}
