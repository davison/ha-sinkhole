#!/bin/bash
# shellcheck shell=bash
set -euo pipefail
IFS=$'\n\t'

readonly script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
source "$script_dir/lib-utils.sh"
no_root


exit 0

