# ==============================================================================
# Google Cloud Provider Configuration
# ------------------------------------------------------------------------------
# Purpose:
#   - Configures the Google provider for Terraform.
#   - Authenticates using a service account JSON credentials file.
#
# Notes:
#   - credentials.json must exist at ../credentials.json.
#   - project is dynamically extracted from the decoded JSON.
#   - Avoid committing credentials.json to source control.
# ==============================================================================

provider "google" {
  # --------------------------------------------------------------------------
  # Project context
  # - Reads project_id from the decoded credentials JSON.
  # --------------------------------------------------------------------------
  project = local.credentials.project_id

  # --------------------------------------------------------------------------
  # Authentication
  # - Uses a service account key file for non-interactive Terraform runs.
  # --------------------------------------------------------------------------
  credentials = file("../credentials.json")
}

# ==============================================================================
# Local Variables
# ------------------------------------------------------------------------------
# Decodes the service account JSON for reuse across the configuration.
#
# Key Points:
#   - credentials: full decoded JSON map.
#   - service_account_email: identity used for IAM bindings and modules.
# ==============================================================================

locals {
  # --------------------------------------------------------------------------
  # Full credentials JSON decoded into a map.
  # --------------------------------------------------------------------------
  credentials = jsondecode(file("../credentials.json"))

  # --------------------------------------------------------------------------
  # Service account email extracted from the decoded credentials.
  # --------------------------------------------------------------------------
  service_account_email = local.credentials.client_email
}