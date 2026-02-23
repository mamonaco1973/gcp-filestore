#!/bin/bash
# ==============================================================================
# apply.sh - Two-Phase Terraform Deployment
# ------------------------------------------------------------------------------
# Purpose:
#   - Validates local environment before deployment.
#   - Deploys Active Directory infrastructure (Phase 1).
#   - Deploys dependent server resources (Phase 2).
#   - Runs validation script after successful build.
#
# Behavior:
#   - Fail-fast enabled via strict bash settings.
#   - Script exits immediately on any command failure.
#   - No interactive approval (auto-approve enabled).
#
# Phases:
#   1. 01-directory  -> Core AD infrastructure.
#   2. 02-servers    -> VMs joined to AD.
# ==============================================================================

# ------------------------------------------------------------------------------
# Strict Mode (Fail Fast)
# - -e : Exit immediately if a command fails.
# - -u : Treat unset variables as errors.
# - -o pipefail : Fail if any command in a pipeline fails.
# ------------------------------------------------------------------------------
set -euo pipefail

# ------------------------------------------------------------------------------
# Environment Validation
# - Ensures required tools and credentials exist.
# - Exits automatically if check_env.sh fails.
# ------------------------------------------------------------------------------
./check_env.sh

# ------------------------------------------------------------------------------
# Phase 1: Active Directory Infrastructure
# ------------------------------------------------------------------------------
cd 01-directory

# Initialize Terraform (providers, backend, modules).
terraform init

# Apply AD infrastructure.
terraform apply -auto-approve

cd ..

# ------------------------------------------------------------------------------
# Phase 2: Server Infrastructure (Domain-Joined Instances)
# ------------------------------------------------------------------------------
cd 02-servers

# Initialize Terraform for server deployment.
terraform init

# Apply server resources.
terraform apply -auto-approve

cd ..

# ------------------------------------------------------------------------------
# Post-Deployment Validation
# - Runs validation checks and prints endpoints / access details.
# ------------------------------------------------------------------------------
./validate.sh