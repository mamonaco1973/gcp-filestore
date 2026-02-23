# ==============================================================================
# variables.tf - Mini Active Directory Input Variables
# ------------------------------------------------------------------------------
# Purpose:
#   - Defines domain identity, LDAP structure, and GCP deployment inputs.
#   - Supplies naming and placement parameters for the mini-ad module.
#
# Categories:
#   1. Active Directory identity (dns_zone, realm, netbios).
#   2. LDAP structure (user_base_dn).
#   3. GCP placement (zone, machine_type, networking).
#
# Notes:
#   - Defaults are suitable for demo/testing.
#   - Override via terraform.tfvars for production deployments.
# ==============================================================================


# ==============================================================================
# Active Directory Naming Inputs
# ------------------------------------------------------------------------------
# dns_zone : FQDN of the AD DNS domain.
# realm    : Kerberos realm (usually dns_zone in UPPERCASE).
# netbios  : Short pre-Windows 2000 domain name.
# ==============================================================================


# ------------------------------------------------------------------------------
# DNS Zone / AD Domain (FQDN)
# - Primary DNS namespace for the domain.
# - Used by Samba AD DC for domain identity.
# - Must be a valid, routable FQDN.
# ------------------------------------------------------------------------------
variable "dns_zone" {
  description = "AD DNS zone / domain (e.g., mcloud.mikecloud.com)"
  type        = string
  default     = "mcloud.mikecloud.com"
}


# ------------------------------------------------------------------------------
# Kerberos Realm (UPPERCASE)
# - Convention: match dns_zone but uppercase.
# - Required by Kerberos configuration (krb5).
# - Must exactly match the AD domain in uppercase.
# ------------------------------------------------------------------------------
variable "realm" {
  description = "Kerberos realm (e.g., MCLOUD.MIKECLOUD.COM)"
  type        = string
  default     = "MCLOUD.MIKECLOUD.COM"
}


# ------------------------------------------------------------------------------
# NetBIOS Short Domain Name
# - Legacy short name (<= 15 chars recommended).
# - Typically uppercase alphanumeric.
# - Used by SMB, older Windows clients, and some auth flows.
# ------------------------------------------------------------------------------
variable "netbios" {
  description = "NetBIOS short domain name (e.g., MCLOUD)"
  type        = string
  default     = "MCLOUD"
}


# ------------------------------------------------------------------------------
# User Base DN (LDAP)
# - Distinguished Name where users are created.
# - Must align with the domain components of dns_zone.
# - Example: CN=Users,DC=mcloud,DC=mikecloud,DC=com
# ------------------------------------------------------------------------------
variable "user_base_dn" {
  description = "User base DN for LDAP placement"
  type        = string
  default     = "CN=Users,DC=mcloud,DC=mikecloud,DC=com"
}


# ==============================================================================
# GCP Deployment Inputs
# ------------------------------------------------------------------------------
# Defines compute placement and networking for the mini AD instance.
# ==============================================================================


# ------------------------------------------------------------------------------
# Zone
# - GCP zone for instance deployment.
# - Must align with the region of the defined subnet.
# ------------------------------------------------------------------------------
variable "zone" {
  description = "GCP zone for deployment (e.g., us-central1-a)"
  type        = string
  default     = "us-central1-a"
}


# ------------------------------------------------------------------------------
# Machine Type
# - Compute shape for the mini AD VM.
# - e2-small is minimum recommended.
# - e2-medium default provides additional headroom.
# ------------------------------------------------------------------------------
variable "machine_type" {
  description = "Machine type for mini AD instance"
  type        = string
  default     = "e2-medium"
}


# ------------------------------------------------------------------------------
# VPC Name
# - Name of the VPC network used by the deployment.
# - Must exist if not created in this configuration.
# ------------------------------------------------------------------------------
variable "vpc_name" {
  description = "VPC network name"
  type        = string
  default     = "filestore-vpc"
}


# ------------------------------------------------------------------------------
# Subnetwork Name
# - Subnet where the mini AD VM will be deployed.
# - Must exist in the specified region/zone.
# ------------------------------------------------------------------------------
variable "ad_subnet" {
  description = "Sub-network for mini AD instance"
  type        = string
  default     = "ad-subnet-filestore"
}
