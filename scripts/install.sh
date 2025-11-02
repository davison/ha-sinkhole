#!/bin/bash
# shellcheck shell=bash
set -euo pipefail
IFS=$'\n\t'

readonly script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
readonly project_root=$(dirname "$script_dir")
source "$script_dir/lib-utils.sh"
no_root

readonly install_log="/tmp/ha-sinkhole-install.log"
truncate -s 0 "${install_log}"


# ---------------------------------------------------------------------------
heading "${blue}" "⚙️  Checking environment and dependencies"
# ---------------------------------------------------------------------------

# Check for dependencies
command_check podman loginctl systemctl

# enable long running user services
sudo loginctl enable-linger $USER

sudo mkdir -p /etc/ha-sinkhole
sudo mkdir -p /var/lib/ha-sinkhole/data
if [[ ! -f /etc/ha-sinkhole/sinkhole.env ]]; then
  sudo cp "$project_root/services/sinkhole.example.env" /etc/ha-sinkhole/sinkhole.env
  warn "/etc/ha-sinkhole/sinkhole.env created. Please edit this file to configure your installation then re-run this installer."
  exit 0
fi


# ---------------------------------------------------------------------------
heading "${yellow}" "📦 Installing systemd units"
# ---------------------------------------------------------------------------

# TODO: where does this actually come from? It needs to vary per container
readonly target_version="stable"
if [[ $# -eq 1 && $1 == "latest" ]]; then
  target_version="$1"
fi

sed 's/vip-manager:latest/vip-manager:'"$target_version"'/' "$project_root/services/vip-manager.container" | sudo tee /etc/containers/systemd/vip-manager.container >/dev/null
sed 's/dns-node:latest/dns-node:'"$target_version"'/' "$project_root/services/dns-node.container" | sudo tee /etc/containers/systemd/users/dns-node.container > /dev/null
sed 's/blocklist-updater:latest/blocklist-updater:'"$target_version"'/' "$project_root/services/blocklist-updater.container" | sudo tee /etc/containers/systemd/users/blocklist-updater.container > /dev/null
sudo cp $project_root/services/blocklist-updater.timer /etc/systemd/user/
sudo systemctl daemon-reload
r1=$?
systemctl --user daemon-reload
r2=$?
[ $r1 -eq 0 && $r2 -eq 0 ] || {
    error "Failed to reload systemd daemon with new service files. Please check the output above."
    exit 1
}
success "Systemd service files installed and daemon reloaded."


# ---------------------------------------------------------------------------
heading "${green}" "🚀 Starting services"
# ---------------------------------------------------------------------------

# Enable the timer, not the service. This will trigger the updater
systemctl --user enable blocklist-updater.timer
systemctl --user start dns-node.service
sudo systemctl start vip-manager.service

success "Services started."
exit 0
