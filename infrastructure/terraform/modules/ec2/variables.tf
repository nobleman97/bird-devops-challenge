variable "instance_type" {
  type = string
}

variable "instance_name" {
  type = string
}


# variable "device_index" {
#   type = number
# }

variable "subnet_id" {
  type = string
}

variable "key_name" {
  type = string
}

variable "security_groups" {
  type = list(string)
}


variable "user_data" {
  type = string
}

variable "volume_size" {
  type = number
}

variable "volume_type" {
  type = string
}