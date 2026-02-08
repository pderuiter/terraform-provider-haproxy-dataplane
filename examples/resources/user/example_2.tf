locals {
  user_name = "managed_user"
}

variable "userlist" {
  type = string
}

variable "username" {
  type = string
}

resource "haproxy-dataplane_user" "managed" {
  userlist = var.userlist
  username = var.username

  # Replace with required fields for this object in your environment.
  spec = {}
}

output "user_id" {
  value = haproxy-dataplane_user.managed.id
}
