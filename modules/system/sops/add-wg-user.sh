#!/bin/bash

# Script to add a new WireGuard user
# Usage: ./add-wg-user.sh <username> <description> [secrets-file]

set -e

USERNAME="$1"
DESCRIPTION="$2"
SECRETS_FILE="${3:-secrets.yaml}"

if [ -z "$USERNAME" ] || [ -z "$DESCRIPTION" ]; then
    echo "Usage: $0 <username> <description> [secrets-file]"
    echo "Example: $0 mom-phone \"Mom's iPhone\" secrets.yaml"
    exit 1
fi

if [ ! -f "$SECRETS_FILE" ]; then
    echo "Error: Secrets file '$SECRETS_FILE' not found"
    exit 1
fi

# Check if sops and wg are available
if ! command -v sops &> /dev/null; then
    echo "Error: sops command not found"
    exit 1
fi

if ! command -v wg &> /dev/null; then
    echo "Error: wg command not found (install wireguard-tools)"
    exit 1
fi

echo "Adding new WireGuard user: $USERNAME"
echo "Description: $DESCRIPTION"
echo "Secrets file: $SECRETS_FILE"
echo

# Generate user keys
echo "Generating keys for $USERNAME..."
USER_PRIVATE=$(wg genkey)
USER_PUBLIC=$(echo "$USER_PRIVATE" | wg pubkey)

# Add to SOPS
echo "Adding keys to SOPS..."
sops --set "[\"${USERNAME}_wg_public_key\"] \"$USER_PUBLIC\"" "$SECRETS_FILE"
sops --set "[\"${USERNAME}_wg_private_key\"] \"$USER_PRIVATE\"" "$SECRETS_FILE"

echo "Adding keys to SOPS..."
echo

# Get server info for client config
echo "Retrieving server information..."
SERVER_PUBLIC=$(sops --decrypt --extract '["wireguard_server_public_key"]' "$SECRETS_FILE")
SERVER_ENDPOINT=$(sops --decrypt --extract '["wireguard_server_endpoint"]' "$SECRETS_FILE")

# Print client config to stdout
echo "Client configuration for $USERNAME:"
echo "=================================="
echo "[Interface]"
echo "PrivateKey = $USER_PRIVATE"
echo "Address = 10.0.100.XX/32  # Set this in users.nix"
echo "DNS = 192.168.1.250"
echo ""
echo "[Peer]"
echo "PublicKey = $SERVER_PUBLIC"
echo "Endpoint = $SERVER_ENDPOINT:51820"
echo "AllowedIPs = 192.168.1.0/24  # Adjust based on user group"
echo "PersistentKeepalive = 25"
echo ""
echo "# User: $USERNAME ($DESCRIPTION)"
echo "# Generated: $(date)"
echo "=================================="
echo
echo "Next steps:"
echo "1. Add user to users.nix:"
echo "   \"$USERNAME\" = {"
echo "     ip = \"10.0.100.XX\";  # Choose available IP"
echo "     group = \"family\";    # Choose appropriate group"
echo "     publicKeySecret = \"${USERNAME}_wg_public_key\";"
echo "     allowedIPs = \"192.168.1.0/24\";  # Adjust as needed"
echo "     description = \"$DESCRIPTION\";"
echo "     enabled = true;"
echo "   };"
echo
echo "2. Add SOPS secrets to your sops module:"
echo "   secrets.${USERNAME}_wg_public_key = { owner = \"root\"; mode = \"0644\"; };"
echo "   secrets.${USERNAME}_wg_private_key = { owner = \"\${username}\"; mode = \"0600\"; };"
echo
echo "3. Update the IP address in the client config above"
echo
echo "To regenerate client config later:"
echo "   sops --decrypt --extract '[\"${USERNAME}_wg_private_key\"]' $SECRETS_FILE"
echo
echo "Security reminder:"
echo "- The configuration above contains the private key"
echo "- Share it securely with the user"
echo "- Private keys are safely stored in SOPS for future reference"
