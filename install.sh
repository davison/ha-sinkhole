#!/bin/bash
# shellcheck shell=bash
set -euo pipefail
IFS=$'\n\t'

readonly script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
source "$script_dir/lib-utils.sh"
no_root

# TODO: Check for dependencies: podman, systemd, loginctl
# TODO: get install prefix from args

readonly install-log="/tmp/ha-sinkhole-install.log"
truncate -s 0 "${install-log}"


# ---------------------------------------------------------------------------
heading "${blue}" "⚙️  Checking environment and dependencies"
# ---------------------------------------------------------------------------

# enable long running user services
sudo loginctl enable-linger $USER

mkdir -p /etc/ha-sinkhole
mkdir -p $HOME/.local/ha-sinkhole/data
[ -f /etc/ha-sinkhole/sinkhole.env ] || cp "$script_dir/services/sinkhole.example.env" /etc/ha-sinkhole/sinkhole.env


# ---------------------------------------------------------------------------
heading "${yellow}" "📦 Installing systemd units"
# ---------------------------------------------------------------------------

# TODO: where does this actually come from? It needs to vary per container
readonly target_version="0.1.1"
sed 's/vip-manager:latest/vip-manager:'"$target_version"'/' "$script_dir/services/vip-manager.container" > /etc/containers/system/vip-manager.container
sed 's/dns-node:latest/dns-node:'"$target_version"'/' "$script_dir/services/dns-node.container" > /etc/containers/system/users/dns-node.container
sed 's/blocklist-updater:latest/blocklist-updater:'"$target_version"'/' "$script_dir/services/blocklist-updater.container" > /etc/containers/system/users/blocklist-updater.container
cp $script_dir/services/blocklist-updater.timer /etc/systemd/system/users/
sudo systemctl daemon-reload
systemctl --user daemon-reload

[ $? -eq 0 ] || {
    error "Failed to reload systemd daemon with new service files. Please check the output above."
    exit 1
}
success "Systemd service files installed and daemon reloaded."


# ---------------------------------------------------------------------------
heading "${green}" "🚀 Starting services"
# ---------------------------------------------------------------------------

# Enable the timer, not the service. This will trigger the updater
systemctl --user enable blocklist-updater.timer
# Enable the two long-running services
systemctl --user start dns-node.service
systemctl start vip-manager.service

success "Services started."
exit 0
