#!/bin/bash

# Decred Linux voting wallet setup for Debian and Redhat based distros.

# https://github.com/jzbz/dcr-setup

# Edit service state:
# sudo systemctl {start|status|stop} {dcrd|dcrwallet}

# Check service log:
# journalctl -u {dcrd|dcrwallet}

# Update system and install tools.
t='curl htop'

if command -v apt 2>&1 >/dev/null; then
	sudo apt update -y && sudo apt upgrade -y && sudo apt install -y ${t}
fi

if command -v dnf 2>&1 >/dev/null; then
	sudo dnf update -y && sudo dnf install -y ${t}
fi

# Set Decred version, CPU architecture, binaries archive name.
v=v1.4.0
a=amd64
b=decred-linux-${a}-${v}.tar.gz

# Download Decred binaries archive, manifest, and signature files.
wget https://github.com/decred/decred-binaries/releases/download/${v}/{${b},manifest-${v}.txt,manifest-${v}.txt.asc}

# Verify PGP signature.
gpg --verify manifest-${v}.txt.asc

# Print SHA256 hash from manifest.
cat manifest-${v}.txt | grep ${b}

# Get SHA256 hash of downloaded binary archive.
sha256sum ${b}

# Prompt to check sig/hashes.
read -n1 -r -p "Make sure the two SHA256 checksums above match and that the manifest file has a good PGP signature. To continue press any key."; echo

# Make directories.
sudo mkdir -p /opt/dcr
sudo mkdir -p /var/dcrd
sudo mkdir -p /var/dcrwallet

# Extract Decred binaries.
sudo tar -xf ${b} --strip-components 1 -C /opt/dcr/

# Get IP address.
ip=$(curl https://icanhazip.com)

# Create random password.
pw=$(openssl rand -base64 32)

# Prompt for password.
read -p "Input the password you wish to use for the Decred wallet and press "Enter" (you will need to set the same password in the next step upon wallet creation): " wpw

# Create wallet.
sudo /opt/dcr/dcrwallet --appdata=/var/dcrwallet --create

# Create dcrd service.
sudo bash -c 'cat > /etc/systemd/system/dcrd.service <<EOF
[Unit]
Description=dcrd

[Service]
Type=simple
WorkingDirectory=/var/dcrd
ExecStart=/opt/dcr/dcrd -u=dcr -P='${pw}' --notls --appdata=/var/dcrd --externalip='${ip}'
Restart=on-abnormal

[Install]
WantedBy=multi-user.target
EOF'

# Create dcrwallet service.
sudo bash -c 'cat > /etc/systemd/system/dcrwallet.service <<EOF
[Unit]
Description=dcrwallet

[Service]
Type=simple
WorkingDirectory=/var/dcrwallet
ExecStart=/opt/dcr/dcrwallet -u=dcr -P='${pw}' --noclienttls --noservertls --appdata=/var/dcrwallet --pass="'${wpw}'" --enablevoting
Restart=on-abnormal

[Install]
WantedBy=multi-user.target
EOF'

# Enable + start services.
sudo systemctl enable dcrd
sudo systemctl start dcrd
sudo systemctl enable dcrwallet
sudo systemctl start dcrwallet
