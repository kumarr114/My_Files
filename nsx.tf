data "nsxt_policy_transport_zone" "overlay_tz" {
  display_name = "nsx-overlay-transportzone"

}

data "nsxt_policy_edge_cluster" "edge_cluster" {
    display_name = "EC-UnitedStates"
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

data "nsxt_policy_edge_node" "edge_node_1" {
    edge_cluster_path   = data.nsxt_policy_edge_cluster.edge_cluster.path
    display_name        = var.edge_node_1
}

data "nsxt_policy_edge_node" "edge_node_2" {
    edge_cluster_path   = data.nsxt_policy_edge_cluster.edge_cluster.path
    display_name        = var.edge_node_2
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

# Create Tier-0 Gateway
resource "nsxt_policy_tier0_gateway" "tier0_gw" {
    display_name              = "T0-UnitedStates"
    description               = "Tier-0 provisioned by Terraform"
    failover_mode             = "NON_PREEMPTIVE"
    default_rule_logging      = false
    enable_firewall           = false
    force_whitelisting        = true
    ha_mode                   = "ACTIVE_STANDBY"
    edge_cluster_path         = data.nsxt_policy_edge_cluster.edge_cluster.path

    bgp_config {
        ecmp            = false
        local_as_num    = "65003"
        inter_sr_ibgp   = false
        multipath_relax = false
    }

    tag {
        scope = "color"
        tag   = "blue"
    }
}


# Create Tier-1 Gateway
resource "nsxt_policy_tier1_gateway" "tier1_gw1" {
    description               = "Tier-1 provisioned by Terraform"
    display_name              = "T1-EastCoast"
    nsx_id                    = "predefined_id_1"
    edge_cluster_path         = data.nsxt_policy_edge_cluster.edge_cluster.path
    failover_mode             = "NON_PREEMPTIVE"
    default_rule_logging      = "false"
    enable_firewall           = "true"
    enable_standby_relocation = "false"
    force_whitelisting        = "true"
    tier0_path                = nsxt_policy_tier0_gateway.tier0_gw.path
    route_advertisement_types = ["TIER1_STATIC_ROUTES", "TIER1_CONNECTED"]

    tag {
        scope = "color"
        tag   = "Yellow"
    }

}


# Create Tier-1 Gateway
resource "nsxt_policy_tier1_gateway" "tier1_gw2" {
    description               = "Tier-1 provisioned by Terraform"
    display_name              = "T1-WestCoast"
    nsx_id                    = "predefined_id_2"
    edge_cluster_path         = data.nsxt_policy_edge_cluster.edge_cluster.path
    failover_mode             = "NON_PREEMPTIVE"
    default_rule_logging      = "false"
    enable_firewall           = "true"
    enable_standby_relocation = "false"
    force_whitelisting        = "true"
    tier0_path                = nsxt_policy_tier0_gateway.tier0_gw.path
    route_advertisement_types = ["TIER1_STATIC_ROUTES", "TIER1_CONNECTED"]

    tag {
        scope = "color"
        tag   = "Red"
    }

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


# Create Security Groups
resource "nsxt_policy_group" "EastCoast-VMs" {
    display_name = var.nsx_group_web
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
    display_name = var.nsx_group_app
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

