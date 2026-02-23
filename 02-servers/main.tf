# ==============================================================================
# Google Cloud Provider & Local Variables
# ------------------------------------------------------------------------------
# Purpose:
#   - Configures the Google provider for Terraform execution.
#   - Authenticates using a service account JSON key file.
#   - Exposes decoded credential fields as reusable locals.
#
# Notes:
#   - credentials.json must exist at ../credentials.json.
#   - Avoid committing credential files to source control.
#   - project_id and client_email are derived dynamically.
# ==============================================================================

provider "google" {
  # --------------------------------------------------------------------------
  # Project context
  # - Reads project_id from decoded credentials JSON.
  # --------------------------------------------------------------------------
  project = local.credentials.project_id

  # --------------------------------------------------------------------------
  # Authentication
  # - Uses service account key for non-interactive Terraform runs.
  # --------------------------------------------------------------------------
  credentials = file("../credentials.json")
}


# ==============================================================================
# Local Variables
# ------------------------------------------------------------------------------
# Decodes the credentials JSON file and extracts reusable fields.
#
# Key Points:
#   - credentials: full decoded JSON map.
#   - service_account_email: used for IAM bindings and module inputs.
# ==============================================================================

locals {
  # --------------------------------------------------------------------------
  # Full decoded service account JSON.
  # --------------------------------------------------------------------------
  credentials = jsondecode(file("../credentials.json"))

  # --------------------------------------------------------------------------
  # Service account identity extracted from credentials.
  # --------------------------------------------------------------------------
  service_account_email = local.credentials.client_email
}


# ==============================================================================
# Data Sources: Existing Network & Subnet
# ------------------------------------------------------------------------------
# Looks up pre-existing VPC and subnet for resource attachment.
#
# Key Points:
#   - ad-vpc must already exist in the project.
#   - ad-subnet must exist in us-central1 region.
#   - Data sources prevent recreation of shared networking.
# ==============================================================================

data "google_compute_network" "ad_vpc" {
  # --------------------------------------------------------------------------
  # Reference existing VPC by name.
  # --------------------------------------------------------------------------
  name = var.vpc_name
}

data "google_compute_subnetwork" "ad_subnet" {
  # --------------------------------------------------------------------------
  # Reference existing subnet by name and region.
  # --------------------------------------------------------------------------
  name   = var.ad_subnet
  region = "us-central1"
}