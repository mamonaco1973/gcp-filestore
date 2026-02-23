#!/bin/bash
# ==============================================================================
# check_env.sh - Environment Validation for GCP + Terraform
# ------------------------------------------------------------------------------
# Purpose:
#   - Verifies required CLI tools are installed and in PATH.
#   - Confirms credentials.json exists in current directory.
#   - Authenticates gcloud using the service account key.
#   - Exports GOOGLE_APPLICATION_CREDENTIALS for Terraform usage.
#
# Requirements:
#   - gcloud CLI installed.
#   - terraform CLI installed.
#   - jq not required in this script.
#   - credentials.json present in current working directory.
#
# Notes:
#   - Intended to fail fast before any Terraform execution.
#   - Designed for local or CI/CD automation workflows.
# ==============================================================================

echo "NOTE: Validating that required commands are found in the PATH."

# ------------------------------------------------------------------------------
# Required CLI Commands
# - Add additional tools here if future modules require them.
# ------------------------------------------------------------------------------
commands=("gcloud" "terraform" "jq")

# ------------------------------------------------------------------------------
# Command Validation Loop
# - Uses command -v to check availability.
# - Tracks overall validation status via all_found flag.
# ------------------------------------------------------------------------------
all_found=true

for cmd in "${commands[@]}"; do
  if ! command -v "$cmd" &> /dev/null; then
    echo "ERROR: $cmd is not found in the current PATH."
    all_found=false
  else
    echo "NOTE: $cmd is found in the current PATH."
  fi
done

# ------------------------------------------------------------------------------
# Final Validation Result
# - Exit immediately if any required command is missing.
# ------------------------------------------------------------------------------
if [ "$all_found" = true ]; then
  echo "NOTE: All required commands are available."
else
  echo "ERROR: One or more commands are missing."
  exit 1
fi

echo "NOTE: Validating credentials.json and testing gcloud authentication"

# ------------------------------------------------------------------------------
# Validate credentials.json Exists
# - Required for non-interactive service account authentication.
# ------------------------------------------------------------------------------
if [[ ! -f "./credentials.json" ]]; then
  echo "ERROR: The file './credentials.json' does not exist." >&2
  exit 1
fi

# ------------------------------------------------------------------------------
# Authenticate gcloud Using Service Account
# - Activates the service account for CLI usage.
# ------------------------------------------------------------------------------
gcloud auth activate-service-account --key-file="./credentials.json"

# ------------------------------------------------------------------------------
# Export GOOGLE_APPLICATION_CREDENTIALS
# - Allows Terraform and SDK-based tools to auto-detect credentials.
# - Uses absolute path to avoid relative path issues.
# ------------------------------------------------------------------------------
export GOOGLE_APPLICATION_CREDENTIALS="$(pwd)/credentials.json"