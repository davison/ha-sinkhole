#!/usr/bin/env bash
# shellcheck shell=bash
set -euo pipefail
IFS=$'\n\t'

# ---------------------------------------------------------------------------
heading "${red}" "🚀 Removing ha-sinkhole"
# ---------------------------------------------------------------------------

sudo systemctl stop vip-manager
systemctl --user stop dns-node
systemctl --user disable blocklist-updater.timer
sudo mv /etc/ha-sinkhole/sinkhole.env /etc/ha-sinkhole/sinkhole.env.old || true
sudo rm -f /etc/containers/systemd/vip-manager.container \
    /etc/containers/systemd/users/dns-node.container \
    /etc/containers/systemd/users/blocklist-updater.container \
    /etc/systemd/user/blocklist-updater.timer \
    /etc/ha-sinkhole/sinkhole.env \
    /var/lib/ha-sinkhole/data/blocklists.hosts
sudo systemctl daemon-reload
systemctl --user daemon-reload

success "Services uninstalled."
ls -al /etc/ha-sinkhole/sinkhole.env.old || echo "No previous config found."
