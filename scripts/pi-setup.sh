#!/bin/bash
#
# Raspberry Pi IoT Fleet Setup Script
# Run this on the Raspberry Pi to install Mender client and MeshCentral agent
#

set -e

SERVER_IP="192.168.83.161"
MENDER_PORT="8080"
MENDER_HTTPS="true"
MESHCENTRAL_PORT="4430"

# Get Raspberry Pi hostname
PI_HOSTNAME=$(hostname)

echo "======================================"
echo "IoT Fleet - Raspberry Pi Setup"
echo "======================================"
echo "Server IP: $SERVER_IP"
echo ""

# Check if running on ARM architecture
ARCH=$(uname -m)
if [[ ! "$ARCH" =~ ^(aarch64|armv7l|armv8)$ ]]; then
    echo "Warning: This script is designed for ARM-based Raspberry Pi"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Update system
echo "Updating system packages..."
sudo apt update

# Install Mender Client
echo ""
echo "Installing Mender Client..."
if ! command -v mender &> /dev/null; then
    # Add Mender repository
    wget -O- https://downloads.mender.io/repos/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/mender-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/mender-archive-keyring.gpg] https://downloads.mender.io/repos/debian stable main" | sudo tee /etc/apt/sources.list.d/mender.list

    sudo apt update
    sudo apt install -y mender-client mender-connect
else
    echo "Mender client already installed"
fi

# Configure Mender
echo ""
echo "Configuring Mender Client..."
sudo mkdir -p /etc/mender

MENDER_URL="https://$SERVER_IP:$MENDER_PORT"
if [ "$MENDER_HTTPS" = "false" ]; then
    MENDER_URL="http://$SERVER_IP:$MENDER_PORT"
fi

cat <<EOF | sudo tee /etc/mender/mender.conf
{
  "ServerURL": "$MENDER_URL",
  "UpdatePollIntervalSeconds": 1800,
  "InventoryPollIntervalSeconds": 1800,
  "RetryPollIntervalSeconds": 300,
  "ServerCertificate": "",
  "SkipVerify": true
}
EOF

# Enable and start Mender
echo "Enabling Mender services..."
sudo systemctl enable mender-client
sudo systemctl restart mender-client

# Check Mender status
echo ""
echo "Mender Client Status:"
sudo systemctl status mender-client --no-pager -l | head -10

# Install MeshCentral Agent
echo ""
echo "======================================"
echo "Installing MeshCentral Agent..."
echo "======================================"
echo ""
echo "Please complete the following steps:"
echo "1. Open your browser and go to: https://$SERVER_IP:$MESHCENTRAL_PORT"
echo "2. Log in to MeshCentral"
echo "3. Click 'Add Agent' or go to 'My Devices'"
echo "4. Select 'Linux ARM / Raspberry Pi'"
echo "5. Copy the installation command"
echo "6. Run that command on this Raspberry Pi"
echo ""
echo "The command will look something like:"
echo "wget -q https://$SERVER_IP:$MESHCENTRAL_PORT/meshagents?id=... -O meshagent && chmod +x meshagent && sudo ./meshagent -install"
echo ""

# Summary
echo ""
echo "======================================"
echo "Setup Summary"
echo "======================================"
echo "Mender Client: Installed and configured"
echo "  - Server: http://$SERVER_IP:$MENDER_PORT"
echo "  - Status: $(sudo systemctl is-active mender-client)"
echo ""
echo "MeshCentral Agent: Manual installation required"
echo "  - Dashboard: https://$SERVER_IP:$MESHCENTRAL_PORT"
echo ""
echo "Next steps:"
echo "1. Accept this device in Mender dashboard: http://$SERVER_IP:$MENDER_PORT"
echo "2. Install MeshCentral agent using the command from the web UI"
echo ""
