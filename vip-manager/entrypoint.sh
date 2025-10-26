#!/bin/bash

set -euo pipefail

# --- Required Variables ---
# These MUST be set by the user
: "${VIRTUAL_IP?Missing VIRTUAL_IP. Set this to the floating IP address.}"
: "${VRRP_PASSWORD?Missing VRRP_PASSWORD. Set this for VRRP authentication.}"

# --- Optional Variables with Defaults ---

# Default to BACKUP state. Keepalived will elect a MASTER based on priority.
export NODE_STATE=${NODE_STATE:-BACKUP}

# Default priority. All nodes can share 100; highest IP wins ties.
export NODE_PRIORITY=${NODE_PRIORITY:-100}

# Default router ID to the container's hostname for uniqueness.
# Quote command substitution (SC2046)
export VRRP_ROUTER_ID=${VRRP_ROUTER_ID:-"$(hostname)"}

# Try to auto-detect the default interface.
# '|| true' prevents 'set -e' from exiting if the pipe fails (e.g., no route).
DEFAULT_INTERFACE=$(ip route get 8.8.8.8 2>/dev/null | awk '{print $5}' | head -n1 || true)
export INTERFACE=${INTERFACE:-$DEFAULT_INTERFACE}

# Final check for the interface, in case auto-detection failed.
# This check is now critical if the auto-detection failed.
: "${INTERFACE?Missing INTERFACE. Could not auto-detect. Please set manually.}"

# --- Configuration Generation ---

# Quote variables in echo statements (SC2086)
echo "--- Keepalived Configuration ---"
echo "VIRTUAL_IP:     \"$VIRTUAL_IP\""
echo "INTERFACE:      \"$INTERFACE\""
echo "NODE_STATE:     \"$NODE_STATE\""
echo "NODE_PRIORITY:  \"$NODE_PRIORITY\""
echo "VRRP_ROUTER_ID: \"$VRRP_ROUTER_ID\""
echo "VRRP_PASSWORD:  [set]"
echo "--------------------------------"

echo "Generating keepalived.conf..."

# 1. Run as ROOT: Substitute env vars and create final config
envsubst < /etc/keepalived/keepalived.conf.template > /etc/keepalived/keepalived.conf

echo "Starting Keepalived..."
# Use exec to replace the shell process with keepalived (good for PID 1)
exec keepalived -n -f /etc/keepalived/keepalived.conf --dont-fork
