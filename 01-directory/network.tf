# ==============================================================================
# Custom VPC, Subnet, Router, and NAT for Active Directory
# ------------------------------------------------------------------------------
# Purpose:
#   - Provisions isolated networking for the Mini-AD environment.
#   - Creates custom VPC, dedicated subnet, Cloud Router, and Cloud NAT.
#
# Architecture:
#   1. Custom-mode VPC (no default subnets).
#   2. Regional subnet for AD resources.
#   3. Cloud Router (required for NAT).
#   4. Cloud NAT for outbound-only internet access.
#
# Notes:
#   - Instances remain private (no external IPs required).
#   - NAT provides secure egress for package installs and updates.
# ==============================================================================


# ==============================================================================
# VPC Network: Active Directory VPC
# ------------------------------------------------------------------------------
# Creates a custom-mode VPC named "ad-vpc".
#
# Key Points:
#   - auto_create_subnetworks = false disables default subnet creation.
#   - All subnets must be explicitly defined.
# ==============================================================================

resource "google_compute_network" "ad_vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
}


# ==============================================================================
# Subnet: Active Directory Subnet
# ------------------------------------------------------------------------------
# Defines a regional subnet for AD resources.
#
# Key Points:
#   - Region: us-central1.
#   - CIDR: 10.1.0.0/24.
#   - Must not overlap with other networks.
#   - Attached to the custom VPC above.
# ==============================================================================

resource "google_compute_subnetwork" "ad_subnet" {
  name          = var.ad_subnet
  region        = "us-central1"
  network       = google_compute_network.ad_vpc.id
  ip_cidr_range = "10.1.0.0/24"
}


# ==============================================================================
# Cloud Router
# ------------------------------------------------------------------------------
# Creates a regional Cloud Router in the AD VPC.
#
# Key Points:
#   - Required for Cloud NAT.
#   - Supports dynamic routing and BGP if later configured.
#   - Must exist before NAT can be attached.
# ==============================================================================

resource "google_compute_router" "ad_router" {
  name    = "ad-nfs-router"
  network = google_compute_network.ad_vpc.id
  region  = "us-central1"
}


# ==============================================================================
# Cloud NAT
# ------------------------------------------------------------------------------
# Provides outbound internet access for private AD resources.
#
# Key Points:
#   - NAT IPs automatically allocated (AUTO_ONLY).
#   - Applies to all subnets and IP ranges in the VPC.
#   - Flow logging enabled with filter set to ALL.
#   - Eliminates need for public IPs on AD instances.
# ==============================================================================

resource "google_compute_router_nat" "ad_nat" {
  name   = "ad-nfs-nat"
  router = google_compute_router.ad_router.name
  region = google_compute_router.ad_router.region

  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ALL"
  }
}