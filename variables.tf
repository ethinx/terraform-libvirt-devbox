variable "vm_count" {
  type    = number
  default = 1
}

variable "kind" {
  type    = string
  default = "general"
}

variable "project" {
  type    = string
  default = "tubuntu"
}

variable "disk_size" {
  type    = number
  default = 64424509440
}

variable "cpu" {
  type    = number
  default = 2
}

variable "memory" {
  type    = number
  default = 4096
}

variable "libvirt_mode" {
  type = string
}

variable "libvirt_user" {
  type = string
}

variable "libvirt_remote_host" {
  type = string
}

variable "colo" {
  type    = string
  default = "local"
}

variable "org_domain" {
  type    = string
  default = "lab.com"
}

variable "github_id" {
  type = string
}

variable "libvirt_pool_path" {
  type    = string
  default = "/data/libvirt_pool"
}

variable "cluster_ssh_pub_key" {
  type = string
}

variable "cluster_ssh_secret_key" {
  type = string
}

