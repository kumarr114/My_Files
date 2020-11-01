#extending from partial-US-Topology.
# 1. Adding HA VIP on PuertoRico.

data "nsxt_policy_transport_zone" "overlay_tz" {
  display_name = "nsx-overlay-transportzone"

}

data "nsxt_policy_transport_zone" "vlan_tz" {
    display_name = "nsx-vlan-transportzone"
}

data "nsxt_policy_edge_cluster" "edge_cluster1" {
    display_name = "EC-UnitedStates"
}

data "nsxt_policy_edge_node" "edge_node_1" {
    edge_cluster_path   = data.nsxt_policy_edge_cluster.edge_cluster1.path
    display_name        = var.edge_node_1
}

data "nsxt_policy_edge_node" "edge_node_2" {
    edge_cluster_path   = data.nsxt_policy_edge_cluster.edge_cluster1.path
    display_name        = var.edge_node_2
}

data "nsxt_policy_edge_cluster" "edge_cluster2" {
    display_name = "EC-PuertoRico"
}


data "nsxt_policy_edge_node" "edge_node_3" {
    edge_cluster_path   = data.nsxt_policy_edge_cluster.edge_cluster2.path
    display_name        = var.edge_node_3
}

data "nsxt_policy_edge_node" "edge_node_4" {
    edge_cluster_path   = data.nsxt_policy_edge_cluster.edge_cluster2.path
    display_name        = var.edge_node_4
}


data "nsxt_policy_service" "ssh" {
    display_name = "SSH"
}

data "nsxt_policy_service" "http" {
    display_name = "HTTP"
}

data "nsxt_policy_service" "https" {
    display_name = "HTTPS"
}




# NSX-T Manager Credentials
provider "nsxt" {
    host                     = var.nsx_manager
    username                 = var.username
    password                 = var.password
    allow_unverified_ssl     = true
    max_retries              = 10
    retry_min_delay          = 500
    retry_max_delay          = 5000
    retry_on_status_codes    = [429]
}

# Create NSX-T VLAN Segments for Uplink connection

resource "nsxt_policy_vlan_segment" "vlan2135" {
    display_name = "vlan2135"
    description = "VLAN Segment created by Terraform"
    transport_zone_path = data.nsxt_policy_transport_zone.vlan_tz.path
    vlan_ids = ["2135"]
}

# Create Tier-0 Gateway UnitedStates
resource "nsxt_policy_tier0_gateway" "tier0_gw1" {
    display_name              = "T0-UnitedStates"
    description               = "Tier-0 provisioned by Terraform"
    failover_mode             = "NON_PREEMPTIVE"
    default_rule_logging      = false
    enable_firewall           = false
    force_whitelisting        = true
    ha_mode                   = "ACTIVE_STANDBY"
    edge_cluster_path         = data.nsxt_policy_edge_cluster.edge_cluster1.path

    bgp_config {
        ecmp            = false
        local_as_num    = "65003"
        inter_sr_ibgp   = false
        multipath_relax = false
    }

}


# Create Tier-0 Gateway PuertoRico
resource "nsxt_policy_tier0_gateway" "tier0_gw2" {
    display_name              = "T0-PuertoRico"
    description               = "Tier-0 provisioned by Terraform"
    failover_mode             = "NON_PREEMPTIVE"
    default_rule_logging      = false
    enable_firewall           = false
    force_whitelisting        = true
    ha_mode                   = "ACTIVE_STANDBY"
    edge_cluster_path         = data.nsxt_policy_edge_cluster.edge_cluster2.path

    bgp_config {
        ecmp            = false
        local_as_num    = "65004"
        inter_sr_ibgp   = false
        multipath_relax = false
    }

}

# Create Tier-0 Gateway Uplink Interfaces on PuertoRico

resource "nsxt_policy_tier0_gateway_interface" "uplink1" {
    display_name        = "Uplink-01"
    description         = "Uplink to VLAN 2135"
    type                = "EXTERNAL"
    edge_node_path      = data.nsxt_policy_edge_node.edge_node_3.path
    gateway_path        = nsxt_policy_tier0_gateway.tier0_gw2.path
    segment_path        = nsxt_policy_vlan_segment.vlan2135.path
    subnets             = ["172.16.135.91/24"]
    mtu                 = 9000
}

resource "nsxt_policy_tier0_gateway_interface" "uplink2" {
    display_name        = "Uplink-02"
    description         = "Uplink to VLAN 2135"
    type                = "EXTERNAL"
    edge_node_path      = data.nsxt_policy_edge_node.edge_node_4.path
    gateway_path        = nsxt_policy_tier0_gateway.tier0_gw2.path
    segment_path        = nsxt_policy_vlan_segment.vlan2135.path
    subnets             = ["172.16.135.92/24"]
    mtu                 = 9000
}

resource "nsxt_policy_tier0_gateway_ha_vip_config" "ha-vip" {
  config {
    enabled                  = true
    external_interface_paths = [nsxt_policy_tier0_gateway_interface.uplink1.path, nsxt_policy_tier0_gateway_interface.uplink2.path]
    vip_subnets              = ["172.16.135.90/24"]
  }
}

# Create Tier-1 Gateway PuertoRico
resource "nsxt_policy_tier1_gateway" "tier1_gw3" {
    description               = "Tier-1 provisioned by Terraform"
    display_name              = "T1-PuertoRico"
    nsx_id                    = "predefined_id_3"
    edge_cluster_path         = data.nsxt_policy_edge_cluster.edge_cluster2.path
    failover_mode             = "NON_PREEMPTIVE"
    default_rule_logging      = "false"
    enable_firewall           = "true"
    enable_standby_relocation = "false"
    force_whitelisting        = "true"
    tier0_path                = nsxt_policy_tier0_gateway.tier0_gw2.path
    route_advertisement_types = ["TIER1_STATIC_ROUTES", "TIER1_CONNECTED"]


}


# Create Tier-1 Gateway
resource "nsxt_policy_tier1_gateway" "tier1_gw1" {
    description               = "Tier-1 provisioned by Terraform"
    display_name              = "T1-EastCoast"
    nsx_id                    = "predefined_id_1"
    edge_cluster_path         = data.nsxt_policy_edge_cluster.edge_cluster1.path
    failover_mode             = "NON_PREEMPTIVE"
    default_rule_logging      = "false"
    enable_firewall           = "true"
    enable_standby_relocation = "false"
    force_whitelisting        = "true"
    tier0_path                = nsxt_policy_tier0_gateway.tier0_gw1.path
    route_advertisement_types = ["TIER1_STATIC_ROUTES", "TIER1_CONNECTED"]


}


# Create Tier-1 Gateway
resource "nsxt_policy_tier1_gateway" "tier1_gw2" {
    description               = "Tier-1 provisioned by Terraform"
    display_name              = "T1-WestCoast"
    nsx_id                    = "predefined_id_2"
    edge_cluster_path         = data.nsxt_policy_edge_cluster.edge_cluster1.path
    failover_mode             = "NON_PREEMPTIVE"
    default_rule_logging      = "false"
    enable_firewall           = "true"
    enable_standby_relocation = "false"
    force_whitelisting        = "true"
    tier0_path                = nsxt_policy_tier0_gateway.tier0_gw1.path
    route_advertisement_types = ["TIER1_STATIC_ROUTES", "TIER1_CONNECTED"]


}

# Create NSX-T Overlay Segments
resource "nsxt_policy_segment" "EastCoast-Seg" {
    display_name        = var.nsx_segment_web
    description         = "Segment created by Terraform"
    transport_zone_path = data.nsxt_policy_transport_zone.overlay_tz.path
    connectivity_path   = nsxt_policy_tier1_gateway.tier1_gw1.path

    subnet {
        cidr        = "192.168.10.1/24"
        # dhcp_ranges = ["172.16.10.50-172.16.10.100"]

        # dhcp_v4_config {
        #     lease_time  = 36000
        #     dns_servers = ["10.29.12.197"]
        # }
    }
}

resource "nsxt_policy_segment" "WestCoast-Seg" {
    display_name        = var.nsx_segment_app
    description         = "Segment created by Terraform"
    transport_zone_path = data.nsxt_policy_transport_zone.overlay_tz.path
    connectivity_path   = nsxt_policy_tier1_gateway.tier1_gw2.path

    subnet {
        cidr        = "192.168.20.1/24"
        # dhcp_ranges = ["172.16.10.50-172.16.10.100"]

        # dhcp_v4_config {
        #     lease_time  = 36000
        #     dns_servers = ["10.29.12.197"]
        # }
    }
}

resource "nsxt_policy_segment" "PuertoRico-Seg" {
    display_name        = "PuertoRico-Seg"
    description         = "Segment created by Terraform"
    transport_zone_path = data.nsxt_policy_transport_zone.overlay_tz.path
    connectivity_path   = nsxt_policy_tier1_gateway.tier1_gw3.path

    subnet {
        cidr        = "192.168.30.1/24"
        # dhcp_ranges = ["172.16.10.50-172.16.10.100"]

        # dhcp_v4_config {
        #     lease_time  = 36000
        #     dns_servers = ["10.29.12.197"]
        # }
    }
}

# Create Security Groups
resource "nsxt_policy_group" "EastCoast-VMs" {
    display_name = "EastCoast-VMs"
    description  = "Terraform provisioned Group"

    criteria {
        condition {
            key         = "Tag"
            member_type = "VirtualMachine"
            operator    = "CONTAINS"
            value       = "Server"
        }
    }
}

# Create Security Groups
resource "nsxt_policy_group" "WestCoast-VMs" {
    display_name = "WestCoast-VMs"
    description  = "Terraform provisioned Group"

    criteria {
        condition {
            key         = "Tag"
            member_type = "VirtualMachine"
            operator    = "CONTAINS"
            value       = "Santa"
        }
    }
}

resource "nsxt_policy_group" "PuertoRico-VMs" {
    display_name = "PuertoRico-VMs"
    description  = "Terraform provisioned Group"

    criteria {
        condition {
            key         = "Tag"
            member_type = "VirtualMachine"
            operator    = "CONTAINS"
            value       = "Puerto"
        }
    }
}


