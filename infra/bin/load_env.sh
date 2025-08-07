#!/bin/bash
# set -euo pipefail
GIT_PS1_SHOWCONFLICTSTATE=${GIT_PS1_SHOWCONFLICTSTATE:-0}

# Function to load environment variables from a file
load_env_file() {
  local env_file="$1"
  if [[ -f "$env_file" ]]; then
    echo "✅ Loading environment from $env_file"
    export $(grep -v '^#' "$env_file" | xargs)
  else
    echo "❌ Env file $env_file not found!"
    exit 1
  fi
}

# Detect current Terraform workspace
if ! command -v terraform &> /dev/null; then
  echo "❌ Terraform not found in PATH."
  exit 1
fi

WORKSPACE=$(terraform workspace show 2>/dev/null || echo "default")
ENV_FILE=".env.$WORKSPACE"

# Fallback to .env if workspace-specific file doesn't exist
if [[ ! -f "$ENV_FILE" ]]; then
  echo "⚠️  $ENV_FILE not found, falling back to .env"
  ENV_FILE=".env"
fi

load_env_file "$ENV_FILE"

echo "✅ Environment ready (Terraform workspace: $WORKSPACE)"
