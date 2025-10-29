#!/bin/bash
# shellcheck shell=bash
set -euo pipefail
IFS=$'\n\t'

readonly script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
source "$script_dir/lib-utils.sh"
needs_root

readonly install-log="/var/log/ha-sinkhole-install.log"
truncate -s 0 "${install-log}"

# --- Checks ---
heading "${blue}" "⚙️  Checking environment and dependencies"

mkdir -p /etc/ha-sinkhole
mkdir -p /var/lib/ha-sinkhole/data
chmod -R 755 /var/lib/ha-sinkhole
[ -f /etc/ha-sinkhole/sinkhole.env ] || cp "$script_dir/services/sinkhole.example.env" /etc/ha-sinkhole/sinkhole.env

heading "${yellow}" "📦 Installing systemd units"
cp "$script_dir/services/"*.service /etc/systemd/system/
cp "$script_dir/services/"*.timer /etc/systemd/system/
systemctl daemon-reload
[ $? -eq 0 ] || {
    error "Failed to reload systemd daemon with new service files. Please check the output above."
    exit 1
}
success "Systemd service files installed and daemon reloaded."

# Enable the two long-running services
systemctl enable vip-manager.service
systemctl enable dns-node.service
# Enable the timer, not the service. This will trigger the updater
systemctl enable blocklist-updater.timer


# Start the services
for service in vip-manager dns-node blocklist-updater.timer; do
    run_with_spinner "Starting ${service}..." ${install-log} systemctl start "${service}"
    if [ $? -ne 0 ]; then
        error "Failed to start ${service}. Please check ${install-log} for details."
        exit 1
    else
        success "OK"
    fi
done

exit 0

