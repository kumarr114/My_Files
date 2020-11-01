# Variables

variable "nsx_manager" {
    default = "172.16.105.19"
}

# Username & Password for NSX-T Manager
variable "username" {
  default = "admin"
}

variable "password" {
    default = "VMware1VMware!"
}

# Enter Edge Nodes Display Name. Required for external interfaces.
variable "edge_node_1" {
    default = "wld1-edge7"
}

variable "edge_node_2" {
    default = "wld1-edge8"
}