#!/bin/bash
# ==============================================================================
# destroy.sh - Two-Phase Terraform Teardown
# ------------------------------------------------------------------------------
# Purpose:
#   - Destroys server resources first (Phase 1).
#   - Destroys Active Directory infrastructure second (Phase 2).
#
# Order Matters:
#   1. 02-servers   -> Domain-joined VMs and dependent resources.
#   2. 01-directory -> Core AD infrastructure and networking.
#
# Behavior:
#   - Fail-fast enabled via strict bash settings.
#   - Exits immediately if any command fails.
#   - No interactive approval (auto-approve enabled).
# ==============================================================================

# ------------------------------------------------------------------------------
# Strict Mode (Fail Fast)
# - -e : Exit immediately on error.
# - -u : Treat unset variables as errors.
# - -o pipefail : Fail on pipeline errors.
# ------------------------------------------------------------------------------
set -euo pipefail

# ------------------------------------------------------------------------------
# Phase 1: Destroy Server Infrastructure
# ------------------------------------------------------------------------------
cd 02-servers

# Initialize Terraform (ensures providers/backend are ready).
terraform init

# Destroy server resources (VMs, firewall tags, etc.).
terraform destroy -auto-approve

cd ..

# ------------------------------------------------------------------------------
# Phase 2: Destroy Active Directory Infrastructure
# ------------------------------------------------------------------------------
cd 01-directory

# Initialize Terraform for directory stack.
terraform init

# Destroy AD resources (domain controller, networking, etc.).
terraform destroy -auto-approve

cd ..