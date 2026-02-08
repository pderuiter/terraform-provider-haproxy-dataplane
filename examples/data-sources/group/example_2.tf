locals {
  group_lookup_name = "existing_group"
}

variable "userlist" {
  type = string
}

data "haproxy-dataplane_group" "selected" {
  userlist = var.userlist
}

output "group_id" {
  value = data.haproxy-dataplane_group.selected.id
}
