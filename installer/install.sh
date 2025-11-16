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
installer_container=ghcr.io/davison/ha-sinkhole/installer:latest

error_exit() {
    echo "❌ ERROR: $1" >&2
    exit 1
}

usage() {
    echo "Usage: $0 -f <path/to/inventory.yaml> -c <command_to_execute>"
    echo "Options:"
    echo "  -f <file>   Path to the .yaml or .yml inventory file."
    echo "  -c <cmd>    The command to execute."
    echo "If options are missing, the script will prompt for values at runtime."
    exit 0
}

if ! command -v podman &> /dev/null; then
    container_cmd=docker
fi

if ! command -v $container_cmd &> /dev/null; then
    error_exit "Neither podman nor docker is installed. Please install one of them to proceed."
fi

if [[ -z "${SSH_AUTH_SOCK:-}" || ! -S $SSH_AUTH_SOCK ]]; then
    error_exit "SSH_AUTH_SOCK is not set or is not accessible. Please ensure your SSH agent is running, your key is added and the environment variable is set."
fi

while getopts ":f:c:h" opt; do
    case "${opt}" in
        f)
            inventory_file="${OPTARG}"
            ;;
        c)
            playbook="${OPTARG}"
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


# --- 4. Runtime Input and Validation ---

# Prompt for config file if not provided
if [[ -z "$inventory_file" ]]; then
    while true; do
        read -r -p "❓ Inventory file path: " input_file

        # Check if the input is empty
        if [[ -z "$input_file" || "$input_file" =~ ^[[:space:]]*$ ]]; then
            continue
        fi
        
        inventory_file="$input_file"
        break
    done
fi

# Prompt for command if not provided
if [[ -z "$playbook" ]]; then
    while true; do
        read -r -p "❓ Command to run: " input_playbook
        
        if [[ -z "$input_playbook" || "$input_playbook" =~ ^[[:space:]]*$ ]]; then
            continue
        fi

        playbook="$input_playbook"
        break
    done
fi

# --- 6. Execution and Output ---
echo Running installer...

$container_cmd pull "$installer_container"
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
