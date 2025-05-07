#!/bin/bash

# Get the absolute path of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$(dirname "$SCRIPT_DIR")"

# Change to the Terraform directory
cd "$TERRAFORM_DIR" || exit

# Get the current Terraform workspace
CURRENT_WORKSPACE=$(terraform workspace show 2>/dev/null)

if [ -z "$CURRENT_WORKSPACE" ]; then
    echo "Error: Unable to determine the current Terraform workspace."
    exit 1
fi

# Set variables
ENV_PREFIX="${CURRENT_WORKSPACE}"
KEY_NAME="${ENV_PREFIX}_core_instance_access"
KEY_PATH="$HOME/.ssh/aws"
TERRAFORM_PATH="$TERRAFORM_DIR/pub_keys"

# Create .ssh directory if it doesn't exist
mkdir -p "$KEY_PATH"

# Check if the key already exists
if [ -f "$KEY_PATH/$KEY_NAME" ]; then
    echo "Key $KEY_NAME already exists. Skipping key generation."
else
    # Generate the SSH key pair
    ssh-keygen -t rsa -b 4096 -f "$KEY_PATH/$KEY_NAME" -N ""

    # Set correct permissions for the private key
    chmod 400 "$KEY_PATH/$KEY_NAME"

    echo "SSH key pair generated:"
    echo "Private key: $KEY_PATH/$KEY_NAME"
    echo "Public key: $KEY_PATH/$KEY_NAME.pub"
fi

# Create Terraform public keys directory if it doesn't exist
mkdir -p "$TERRAFORM_PATH"

# Always copy the public key to the Terraform directory
cp "$KEY_PATH/$KEY_NAME.pub" "$TERRAFORM_PATH/$KEY_NAME.pub"
echo "Public key copied to: $TERRAFORM_PATH/$KEY_NAME.pub"

echo "SSH key pair is ready for Terraform use."