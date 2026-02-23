# ==============================================================================
# windows.tf - SysAdmin Secret, RDP Firewall, and Windows AD Admin VM
# ------------------------------------------------------------------------------
# Purpose:
#   - Generates SysAdmin credentials and stores them in Secret Manager.
#   - Creates a tag-based firewall rule to allow inbound RDP (TCP/3389).
#   - Deploys a Windows Server 2022 VM for AD administration.
#   - Fetches the latest Windows Server 2022 image at apply time.
#
# Key Points:
#   - SysAdmin password is randomly generated and stored as JSON in a secret.
#   - GCP firewall rules apply via instance network tags (e.g., allow-rdp).
#   - RDP is open to 0.0.0.0/0 (lab only; restrict heavily for production).
#   - Windows VM runs a startup PowerShell script to join the AD domain.
# ==============================================================================


# ==============================================================================
# SysAdmin Credentials (Secret Manager)
# ------------------------------------------------------------------------------
# Generates a strong password for the SysAdmin account and stores it in
# Secret Manager for retrieval by administrators or automation.
#
# Notes:
#   - Secret payload is stored as JSON: { username, password }.
#   - override_special limits special chars to reduce parsing issues.
# ==============================================================================

resource "random_password" "sysadmin_password" {
  length           = 24
  special          = true
  override_special = "-_."
}

resource "google_secret_manager_secret" "sysadmin_secret" {
  secret_id = "sysadmin-ad-credentials"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "admin_secret_version" {
  secret = google_secret_manager_secret.sysadmin_secret.id
  secret_data = jsonencode({
    username = "sysadmin"
    password = random_password.sysadmin_password.result
  })
}


# ==============================================================================
# Firewall Rule: Allow RDP
# ------------------------------------------------------------------------------
# Allows inbound RDP (TCP/3389) to instances tagged with "allow-rdp".
#
# Notes:
#   - Exposing RDP publicly is risky; restrict source_ranges in production.
#   - Consider IAP, VPN, or a bastion instead of 0.0.0.0/0.
# ==============================================================================

resource "google_compute_firewall" "allow_rdp" {
  name    = "allow-rdp"
  network = var.vpc_name

  allow {
    protocol = "tcp"
    ports    = ["3389"]
  }

  # Applies only to instances carrying this network tag.
  target_tags = ["allow-rdp"]

  # Lab only; restrict for production.
  source_ranges = ["0.0.0.0/0"]
}


# ==============================================================================
# Windows AD Management VM
# ------------------------------------------------------------------------------
# Deploys a Windows Server 2022 instance for AD administration tasks.
#
# Notes:
#   - Assigns an external IP for RDP connectivity (lab convenience).
#   - Attaches a service account for API access (secret retrieval, etc.).
#   - Startup script is rendered from a template and executed at first boot.
# ==============================================================================

resource "google_compute_instance" "windows_ad_instance" {
  name         = "win-ad-${random_string.vm_suffix.result}"
  machine_type = "e2-standard-2"
  zone         = "us-central1-a"

  # ----------------------------------------------------------------------------
  # Boot Disk
  # - Uses the latest Windows Server 2022 image from windows-cloud family.
  # ----------------------------------------------------------------------------
  boot_disk {
    initialize_params {
      image = data.google_compute_image.windows_2022.self_link
    }
  }

  # ----------------------------------------------------------------------------
  # Network Interface
  # - Attaches to the AD VPC and subnet.
  # - Adds an ephemeral external IP so RDP can reach the instance.
  # ----------------------------------------------------------------------------
  network_interface {
    network    = var.vpc_name
    subnetwork = var.ad_subnet

    access_config {}
  }

  # ----------------------------------------------------------------------------
  # Service Account
  # - cloud-platform scope is broad; least privilege is better for prod.
  # ----------------------------------------------------------------------------
  service_account {
    email  = local.service_account_email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  # ----------------------------------------------------------------------------
  # Metadata: Startup Script + Admin Credentials
  # - windows-startup-script-ps1 runs once during first boot.
  # - Credentials are provided via metadata for the join process.
  #
  # Note:
  #   - domain_fqdn is hard-coded here; prefer var.dns_zone for consistency.
  # ----------------------------------------------------------------------------
  metadata = {
    windows-startup-script-ps1 = templatefile("./scripts/ad_join.ps1", {
      domain_fqdn = "mcloud.mikecloud.com"
      nfs_gateway = google_compute_instance.nfs_gateway_instance.network_interface[0].network_ip
    })

    admin_username = "sysadmin"
    admin_password = random_password.sysadmin_password.result
  }

  # ----------------------------------------------------------------------------
  # Firewall Tags
  # - Applies the allow-rdp firewall rule to this VM.
  # ----------------------------------------------------------------------------
  tags = ["allow-rdp"]
}


# ==============================================================================
# Data Source: Latest Windows Server 2022 Image
# ------------------------------------------------------------------------------
# Pulls the newest image from the Windows Server 2022 family.
#
# Notes:
#   - Ensures new instances launch with recent patches.
#   - Pin to a specific image if you need strict immutability.
# ==============================================================================

data "google_compute_image" "windows_2022" {
  family  = "windows-2022"
  project = "windows-cloud"
}