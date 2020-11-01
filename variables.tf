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
    default = "wld1-edge1"
}
variable "edge_node_2" {
    default = "wld1-edge2"
}

variable "edge_node_3" {
    default = "wld1-edge7"
}
variable "edge_node_4" {
    default = "wld1-edge8"
}


# Segment Names
variable "nsx_segment_web" {
    default = "EastCoast-Seg"
}
variable "nsx_segment_app" {
    default = "WestCoast-Seg"
}

variable "nsx_segment_db" {
    default = "TF-Segment-DB"
}

# Security Group names.
variable "nsx_group_web" {
    default = "EastCoast-VMs"
}

variable "nsx_group_app" {
    default = "WestCoast-VMs"
}

variable "nsx_group_db" {
    default = "DB Servers"
}

variable "nsx_group_blue" {
    default = "Blue Application"
}