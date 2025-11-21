#!/usr/bin/env bash
# shellcheck shell=bash
#
# Wrapper script for the installer container for ha-sinkhole
#
# -------------------------------------------------------------------------
set -eou pipefail

# Internal variables
inventory_file=""
playbook="install"
container_cmd=podman
manifest_url="https://github.com/davison/ha-sinkhole/releases/download/channel-manifest-artifact/manifest.yaml"
installer_container=""  # Will be set after parsing inventory and fetching manifest

error_exit() {
    printf "🔴 ERROR: $1\n" >&2
    exit 1
}
ok() {
    printf "🟢 $1\n" >&1
}

usage() {
    echo "Usage: $0 -f <path/to/inventory.yaml> -c <command_to_execute>"
    echo "Options:"
    echo "  -f <file>   Path to the .yaml or .yml inventory file."
    echo "  -c <cmd>    The command to execute (defaults to 'install')."
    echo "  -l          Use locally built installer (for development only)."
    echo "If options are missing, the script will prompt for values at runtime."
    exit 0
}

get_channel_from_inventory() {
    local inventory=$1
    
    # Parse channel from inventory, default to 'stable' if not found
    local channel
    channel=$(grep -E "^\s*install_channel:" "$inventory" | awk '{print $2}' | tr -d '"' | head -n1)
    
    if [[ -z "$channel" ]]; then
        echo "stable"  # Default if not specified
    else
        echo "$channel"
    fi
}

# Fetch and parse manifest to get installer version
get_installer_version() {
    local channel=$1
    
    # Fetch manifest
    local manifest
    if ! manifest=$(curl -sSfL "$manifest_url" 2>/dev/null); then
        error_exit "Failed to fetch manifest from $manifest_url"
    fi
    
    # Parse installer version from manifest
    local version
    version=$(echo "$manifest" | awk -v chan="$channel:" '
        $0 ~ chan { in_channel=1 }
        in_channel && /installer:/ { 
            gsub(/[" ]/, "", $2)
            print $2
            exit
        }
    ')
    
    if [[ -z "$version" ]]; then
        error_exit "Could not find installer version for channel '$channel' in manifest"
    fi
    
    echo "$version"
}

ok "Checking environment..."

if ! command -v podman &> /dev/null; then
    container_cmd=docker
fi

if ! command -v $container_cmd &> /dev/null; then
    error_exit "Neither podman nor docker is installed. Please install one of them to proceed."
fi

if [[ -z "${SSH_AUTH_SOCK:-}" || ! -S $SSH_AUTH_SOCK ]]; then
    error_exit "SSH_AUTH_SOCK is not set or is not accessible. Please ensure your SSH agent is running, your key is added and the environment variable is set."
fi

while getopts ":f:c:lh" opt; do
    case "${opt}" in
        f)
            inventory_file="${OPTARG}"
            ;;
        c)
            playbook="${OPTARG}"
            ;;
        l)
            installer_container="localhost/ha-sinkhole/installer:local"
            ;;
        h)
            usage 
            ;;
        :)
            # Handles missing argument for an option (e.g., $0 -f)
            error_exit "Missing argument for -${OPTARG}. See usage with -h."
            ;;
        ?)
            # Handles invalid options (e.g., $0 -x)
            error_exit "Invalid option: -${OPTARG}. See usage with -h."
            ;;
    esac
done

shift "$((OPTIND-1))"

# Prompt for inventory file if not provided
if [[ -z "$inventory_file" ]]; then
    while true; do
        read -r -p "🟡 Inventory file path: " input_file

        # Check if the input is empty
        if [[ -z "$input_file" || "$input_file" =~ ^[[:space:]]*$ ]]; then
            continue
        fi
        
        inventory_file="$input_file"
        break
    done
fi

# Validate inventory file exists
if [[ ! -f "$inventory_file" ]]; then
    error_exit "Inventory file not found: $inventory_file"
fi

# Set installer container version from manifest (unless using local)
if [[ -z "$installer_container" ]]; then
    ok "looking up install channel..."
    channel=$(get_channel_from_inventory "$inventory_file")
    ok "Using channel: $channel"
    ok "Finding installer version from manifest..."
    installer_version=$(get_installer_version "$channel")
    installer_container="ghcr.io/davison/ha-sinkhole/installer:${installer_version}"
fi

ok "Pulling installer container: $installer_version..."
$container_cmd pull "$installer_container" > /dev/null 2>&1 || error_exit "Failed to pull installer container: $installer_container"

ok Running installer...
exit 0

$container_cmd run \
    --rm \
    --net=host \
    --userns=keep-id \
    --name ha-sinkhole-installer \
    -v "$inventory_file":/home/ansible/inventory.yaml \
    -v "$SSH_AUTH_SOCK":/tmp/ssh-agent.sock \
    $installer_container \
    playbooks/"$playbook".yaml

exit 0
