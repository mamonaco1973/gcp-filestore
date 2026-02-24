# ==============================================================================
# nfs.tf - Google Cloud Filestore (Basic NFS) + Firewall
# ------------------------------------------------------------------------------
# Purpose:
#   - Provisions a managed Filestore instance for NFS storage.
#   - Exposes NFS (2049) via firewall for client access.
#
# Key Points:
#   - Basic tiers (HDD/SSD) support NFSv3 only.
#   - Minimum size for Basic tier is 1024 GiB (1 TB).
#   - Filestore is a zonal resource (not regional).
#   - Access is open to 0.0.0.0/0 (lab only; restrict for production).
# ==============================================================================


# ==============================================================================
# Filestore Instance: Basic NFS Server
# ------------------------------------------------------------------------------
# Creates a zonal Filestore instance attached to the AD VPC.
#
# Notes:
#   - Tier controls performance and cost.
#   - BASIC_HDD is lowest cost; suitable for lab workloads.
#   - HIGH_SCALE_SSD / ENTERPRISE support NFSv4.1.
# ==============================================================================

resource "google_filestore_instance" "nfs_server" {

  # ----------------------------------------------------------------------------
  # Core Filestore Settings
  # - Name must be unique within the project.
  # - location must be a zone (e.g., us-central1-b).
  # - project derived from decoded credentials.
  # ----------------------------------------------------------------------------
  name     = "nfs-server"
  tier     = "BASIC_HDD"
  location = "us-central1-b"
  project  = local.credentials.project_id

  # ----------------------------------------------------------------------------
  # File Share Definition
  # - capacity_gb minimum for Basic tier is 1024.
  # - nfs_export_options define access behavior.
  # ----------------------------------------------------------------------------
  file_shares {
    capacity_gb = 1024
    name        = "filestore"

    nfs_export_options {
      access_mode = "READ_WRITE"
      squash_mode = "NO_ROOT_SQUASH"

      # Lab only; restrict to subnet CIDR in production.
      ip_ranges = ["0.0.0.0/0"]
    }
  }

  # ----------------------------------------------------------------------------
  # Network Attachment
  # - Attaches Filestore to the AD VPC.
  # - MODE_IPV4 is default and sufficient for most labs.
  # ----------------------------------------------------------------------------
  networks {
    network = data.google_compute_network.ad_vpc.name
    modes   = ["MODE_IPV4"]
  }
}


# ==============================================================================
# Firewall Rule: Allow NFS (TCP/UDP 2049)
# ------------------------------------------------------------------------------
# Allows inbound NFS traffic for Linux clients mounting Filestore.
#
# Notes:
#   - Required for mount operations over NFSv3.
#   - Restrict source_ranges to trusted CIDRs in production.
# ==============================================================================

resource "google_compute_firewall" "allow_nfs" {
  name    = "allow-nfs-filestore"
  network = data.google_compute_network.ad_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["2049"]
  }

  allow {
    protocol = "udp"
    ports    = ["2049"]
  }

  # Lab only; tighten to your subnet CIDR in production.
  source_ranges = ["0.0.0.0/0"]
}


# ==============================================================================
# Optional Output: Filestore Private IP
# ------------------------------------------------------------------------------
# Exposes the Filestore private IP for mount commands.
#
# Example:
#   mount -t nfs <IP_ADDRESS>:/filestore /mnt
#
# Uncomment if external modules or scripts require this value.
# ==============================================================================

# output "filestore_ip" {
#   value = google_filestore_instance.nfs_server.networks[0].ip_addresses[0]
# }