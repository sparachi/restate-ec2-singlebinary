#!/bin/bash
set -eux

# Directory to install binaries (global)
BIN=/usr/local/bin

# Platform for this EC2
RESTATE_PLATFORM=x86_64-unknown-linux-musl

# Install dependencies
yum install -y xfsprogs unzip curl || true

# Download Restate server and CLI
curl -L --remote-name-all \
    https://restate.gateway.scarf.sh/latest/restate-server-$RESTATE_PLATFORM.tar.xz \
    https://restate.gateway.scarf.sh/latest/restate-cli-$RESTATE_PLATFORM.tar.xz

# Extract binaries
tar -xvf restate-server-$RESTATE_PLATFORM.tar.xz --strip-components=1 restate-server-$RESTATE_PLATFORM/restate-server
tar -xvf restate-cli-$RESTATE_PLATFORM.tar.xz --strip-components=1 restate-cli-$RESTATE_PLATFORM/restate

# Make them executable
chmod +x restate-server restate

# Move binaries to /usr/local/bin
sudo mv restate-server $BIN
sudo mv restate $BIN

# Create system user for restate
sudo useradd --system --create-home --home-dir /var/lib/restate --shell /sbin/nologin restate || true
sudo mkdir -p /var/lib/restate
sudo chown -R restate:restate /var/lib/restate

# Create minimal restate.toml
sudo tee /etc/restate.toml <<EOF
cluster.name = "restate-single"
node.name    = "restate-1"
auto-provision = true

[admin]
bind-address = "0.0.0.0:9070"

[ingress]
bind-address = "0.0.0.0:8080"

[metadata-server]
addresses = ["http://127.0.0.1:5122/"]
replication-factor = 1

[log-server]
addresses = ["http://127.0.0.1:5121/"]
replication-factor = 1
EOF

# Create systemd service
sudo tee /etc/systemd/system/restate-server.service <<EOF
[Unit]
Description=Restate Server
After=network-online.target
Wants=network-online.target

[Service]
User=restate
Group=restate
WorkingDirectory=/var/lib/restate
ExecStart=$BIN/restate-server --config-file /etc/restate.toml
Restart=on-failure
RestartSec=3s
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
sudo systemctl daemon-reload
sudo systemctl enable --now restate-server
sudo systemctl status restate-server || true

# Verify binaries
$BIN/restate-server --version
$BIN/restate --version

echo "Restate server setup complete. Check logs at /var/log/restate-server.log"
echo "You can access the admin UI at http://<instance-ip>:9070"