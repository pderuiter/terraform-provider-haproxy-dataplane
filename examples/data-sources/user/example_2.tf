locals {
  user_lookup_name = "existing_user"
}

variable "userlist" {
  type = string
}

data "haproxy-dataplane_user" "selected" {
  userlist = var.userlist
}

output "user_id" {
  value = data.haproxy-dataplane_user.selected.id
}
