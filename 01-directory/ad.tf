# ==============================================================================
# Mini Active Directory (mini-ad) Module Invocation
# ------------------------------------------------------------------------------
# Purpose:
#   - Invokes the reusable "mini-ad" module to provision an Ubuntu-based
#     Samba 4 AD Domain Controller.
#   - Passes networking, DNS, and authentication inputs into the module.
#   - Supplies AD user definitions via a JSON blob rendered from a template.
#
# Notes:
#   - users_json is rendered locally (templatefile) and handed to the module.
#   - Passwords come from random_password resources defined elsewhere.
#   - depends_on forces NAT/router prerequisites before instance bootstrap.
# ==============================================================================

module "mini_ad" {
  # ----------------------------------------------------------------------------
  # Module source
  # - Pulls the module directly from GitHub.
  # - Keep this pinned to a ref/tag in production for reproducibility.
  # ----------------------------------------------------------------------------
  source = "github.com/mamonaco1973/module-gcp-mini-ad"

  # ----------------------------------------------------------------------------
  # Domain identity inputs
  # ----------------------------------------------------------------------------
  netbios           = var.netbios
  realm             = var.realm
  dns_zone          = var.dns_zone
  user_base_dn      = var.user_base_dn
  ad_admin_password = random_password.admin_password.result

  # ----------------------------------------------------------------------------
  # GCP placement / identity inputs
  # ----------------------------------------------------------------------------
  network      = google_compute_network.ad_vpc.id
  subnetwork   = google_compute_subnetwork.ad_subnet.id
  machine_type = var.machine_type
  email        = local.service_account_email

  # ----------------------------------------------------------------------------
  # Bootstrap user payload
  # - JSON blob used by the module to create users during provisioning.
  # ----------------------------------------------------------------------------
  users_json = local.users_json

  # ----------------------------------------------------------------------------
  # Dependency ordering
  # - Ensure outbound connectivity exists before bootstrapping (apt repos, etc.).
  # ----------------------------------------------------------------------------
  depends_on = [
    google_compute_subnetwork.ad_subnet,
    google_compute_router.ad_router,
    google_compute_router_nat.ad_nat
  ]
}

# ==============================================================================
# Local Variable: users_json
# ------------------------------------------------------------------------------
# Renders ./scripts/users.json.template into a single JSON blob.
#
# Key Points:
#   - Injects environment-specific identity values (DN, realm, netbios, zone).
#   - Injects per-user random passwords for demo/test accounts.
#   - The rendered JSON is passed into the mini-ad module for bootstrap.
# ==============================================================================

locals {
  users_json = templatefile("./scripts/users.json.template", {
    # --------------------------------------------------------------------------
    # Directory / domain identity fields used by the template
    # --------------------------------------------------------------------------
    USER_BASE_DN = var.user_base_dn
    DNS_ZONE     = var.dns_zone
    REALM        = var.realm
    NETBIOS      = var.netbios

    # --------------------------------------------------------------------------
    # Demo user passwords (generated elsewhere)
    # --------------------------------------------------------------------------
    jsmith_password = random_password.jsmith_password.result
    edavis_password = random_password.edavis_password.result
    rpatel_password = random_password.rpatel_password.result
    akumar_password = random_password.akumar_password.result
  })
}