# ==============================================================================
# nfs_gateway.tf - Random Suffix, Firewall Rules, and NFS Gateway VM
# ------------------------------------------------------------------------------
# Purpose:
#   - Generates a unique suffix for resource naming.
#   - Creates firewall rules to allow SSH and SMB to tagged instances.
#   - Deploys an Ubuntu 24.04 VM that joins AD and mounts NFS (Filestore).
#   - Fetches the latest Ubuntu 24.04 LTS image for the boot disk.
#
# Key Points:
#   - Random suffix prevents name collisions across repeated deployments.
#   - SSH/SMB rules are open to 0.0.0.0/0 (lab only; restrict for prod).
#   - VM uses a startup script (templatefile) for AD join + NFS mount.
#   - VM runs with a service account for GCP API access.
# ==============================================================================


# ==============================================================================
# Random String Generator
# ------------------------------------------------------------------------------
# Generates a short, DNS-friendly suffix for uniqueness in resource names.
#
# Notes:
#   - Lowercase only to keep names consistent and compliant.
#   - No special characters to avoid invalid resource names.
# ==============================================================================

resource "random_string" "vm_suffix" {
  length  = 6
  special = false
  upper   = false
}


# ==============================================================================
# Firewall Rule: Allow SSH
# ------------------------------------------------------------------------------
# Allows inbound SSH (TCP/22) to instances tagged with "allow-ssh".
#
# Notes:
#   - source_ranges is open to the internet (0.0.0.0/0) for lab usage.
#   - For production, restrict source_ranges to trusted IPs or IAP.
# ==============================================================================

resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = var.vpc_name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # Tag-based targeting (applies only to instances with this tag).
  target_tags = ["allow-ssh"]

  # Lab only; tighten for production.
  source_ranges = ["0.0.0.0/0"]
}


# ==============================================================================
# Firewall Rule: Allow SMB
# ------------------------------------------------------------------------------
# Allows inbound SMB (TCP/445) to instances tagged with "allow-smb".
#
# Notes:
#   - SMB exposed to the internet is high risk; keep this private in prod.
#   - Prefer VPN / IAP / bastion patterns and restricted source ranges.
# ==============================================================================

resource "google_compute_firewall" "allow_smb" {
  name    = "allow-smb"
  network = var.vpc_name

  allow {
    protocol = "tcp"
    ports    = ["445"]
  }

  # Tag-based targeting (applies only to instances with this tag).
  target_tags = ["allow-smb"]

  # Lab only; tighten for production.
  source_ranges = ["0.0.0.0/0"]
}


# ==============================================================================
# Ubuntu VM: NFS Gateway + AD Join Client
# ------------------------------------------------------------------------------
# Deploys an Ubuntu 24.04 Compute Engine instance that:
#   - Attaches to the AD VPC and subnet.
#   - Runs a startup script to join the AD domain.
#   - Mounts NFS storage exported by a Filestore instance.
#
# Notes:
#   - An ephemeral external IP is assigned for SSH access.
#   - OS Login is enabled via instance metadata.
#   - A service account is attached for API access during bootstrap.
# ==============================================================================

resource "google_compute_instance" "nfs_gateway_instance" {
  name         = "nfs-gateway-${random_string.vm_suffix.result}"
  machine_type = "e2-standard-2"
  zone         = "us-central1-a"

  # ----------------------------------------------------------------------------
  # Boot Disk
  # - Uses the latest Ubuntu 24.04 LTS image from ubuntu-os-cloud.
  # ----------------------------------------------------------------------------
  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu_latest.self_link
    }
  }

  # ----------------------------------------------------------------------------
  # Network Interface
  # - Attaches to the AD VPC and subnet.
  # - Adds an external IP for SSH connectivity (lab convenience).
  # ----------------------------------------------------------------------------
  network_interface {
    network    = var.vpc_name
    subnetwork = var.ad_subnet

    # Ephemeral public IP (required for direct SSH from the internet).
    access_config {}
  }

  # ----------------------------------------------------------------------------
  # Metadata (OS Login + Startup Script)
  # - enable-oslogin enforces IAM-backed SSH via OS Login.
  # - startup-script bootstraps AD join + NFS mount using templated values.
  #
  # Note:
  #   - This template map currently defines domain_fqdn twice.
  #   - The later assignment (var.dns_zone) wins in Terraform maps.
  # ----------------------------------------------------------------------------
  metadata = {
    enable-oslogin = "TRUE"

    startup-script = templatefile("./scripts/nfs_gateway_init.sh", {
      domain_fqdn   = "mcloud.mikecloud.com"
      nfs_server_ip = google_filestore_instance.nfs_server.networks[0].ip_addresses[0]
      domain_fqdn   = var.dns_zone
      netbios       = var.netbios
      force_group   = "mcloud-users"
      realm         = var.realm
    })
  }

  # ----------------------------------------------------------------------------
  # Service Account
  # - cloud-platform scope allows broad API access; least privilege is better
  #   for production, but this is common for lab automation.
  # ----------------------------------------------------------------------------
  service_account {
    email  = local.service_account_email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  # ----------------------------------------------------------------------------
  # Firewall Tags
  # - allow-ssh and allow-smb match rules in this file.
  # - allow-nfs is referenced but the firewall rule is defined elsewhere.
  # ----------------------------------------------------------------------------
  tags = ["allow-ssh", "allow-nfs", "allow-smb"]
}


# ==============================================================================
# Data Source: Latest Ubuntu 24.04 LTS Image
# ------------------------------------------------------------------------------
# Pulls the newest image from the Ubuntu LTS family.
#
# Notes:
#   - Ensures new instances launch with recent patches.
#   - Family images update over time; pin to an image for full immutability.
# ==============================================================================

data "google_compute_image" "ubuntu_latest" {
  family  = "ubuntu-2404-lts-amd64"
  project = "ubuntu-os-cloud"
}