locals {
  group_name = "managed_group"
}

variable "userlist" {
  type = string
}

resource "haproxy-dataplane_group" "managed" {
  name     = local.group_name
  userlist = var.userlist

  # Replace with required fields for this object in your environment.
  spec = {}
}

output "group_id" {
  value = haproxy-dataplane_group.managed.id
}
