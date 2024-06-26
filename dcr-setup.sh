#!/bin/bash

# Decred Linux voting wallet setup for Debian and Redhat based distros.

# https://github.com/jzbz/dcr-setup

# Edit service state:
# sudo systemctl {start|status|stop} {dcrd|dcrwallet}

# Check service log:
# journalctl -u {dcrd|dcrwallet}

# Use dcrctl with:
# dcrctl --rpcuser dcr --rpcpass <password> --rpccert=/var/dcrd/rpc.cert <command>

# Get sudo permissions.
sudo bash

# Update system and install tools.
t='htop'

if command -v apt 2>&1 >/dev/null; then
	apt update -y && apt upgrade -y && apt install -y ${t}
fi

if command -v dnf 2>&1 >/dev/null; then
	dnf update -y && dnf install -y ${t}
fi

# Set Decred version, CPU architecture, binaries archive name.
v=v1.8.1
a=amd64
b=decred-linux-${a}-${v}.tar.gz

# Download Decred binaries archive, manifest, and signature files.
wget https://github.com/decred/decred-binaries/releases/download/${v}/{${b},decred-${v}-manifest.txt,decred-${v}-manifest.txt.asc}

# Verify PGP signature.
gpg --verify decred-${v}-manifest.txt.asc

# Print SHA256 hash from manifest.
cat decred-${v}-manifest.txt | grep ${b}

# Get SHA256 hash of downloaded binary archive.
sha256sum ${b}

# Prompt to check sig/hashes.
read -n1 -r -p "Make sure the two SHA256 checksums above match and that the manifest file has a good PGP signature. To continue press any key."; echo

# Make directories.
mkdir -p /root/decred

# Extract Decred binaries.
tar -xf ${b} --strip-components 1 -C /root/decred/

# Create random password.
pw=$(openssl rand -base64 32)

# Prompt for password.
read -p "Input the password you wish to use for the Decred wallet and press "Enter" (you will need to set the same password in the next step upon wallet creation): " wpw

# Create wallet.
/root/decred/dcrwallet --create

# Create dcrd service.
cat > /etc/systemd/system/dcrd.service <<EOF
[Unit]
Description=dcrd

[Service]
Type=simple
WorkingDirectory=/root/.dcrd
ExecStart=/root/decred/dcrd --appdata=/root/.dcrd -u=dcr -P=${pw}
Restart=on-abnormal

[Install]
WantedBy=multi-user.target
EOF

# Create dcrwallet service.
cat > /etc/systemd/system/dcrwallet.service <<EOF
[Unit]
Description=dcrwallet

[Service]
Type=simple
WorkingDirectory=/root/.dcrwallet
ExecStart=/root/decred/dcrwallet --appdata=/root/.dcrwallet -u=dcr -P=${pw} --pass=\"${wpw}\" --enablevoting
Restart=on-abnormal

[Install]
WantedBy=multi-user.target
EOF

# Enable + start services.
systemctl enable dcrd dcrwallet
systemctl start dcrd dcrwallet
