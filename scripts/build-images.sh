#!/usr/bin/env bash
# shellcheck shell=bash
# ---------------------------------------------------------------------------
# Pass 'clean' as an argument to this script in order to build images with 
# --no-cache specified. Cache is used by default.
# ---------------------------------------------------------------------------

set -euo pipefail
IFS=$'\n\t'

readonly script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly project_root=$(dirname "$script_dir")
source "$script_dir/lib-utils.sh"

discover_images() {
  local containerfile_path container_dir tag_name build_dir_name label_tag
  local output_data=""

  while IFS= read -r containerfile_path; do
    container_dir=$(dirname "$containerfile_path")
    build_dir_name=$(basename "$container_dir")
    tag_name="${image_prefix}/${build_dir_name}:local"    
    output_data+="$tag_name|$build_dir_name"$'\n'

    printf "${blue}>> Found ${yellow}%s${nc} with name and tag ${green}%s${nc}\n" "$build_dir_name" "$tag_name" >&2

  done < <(find "$project_root" -mindepth 2 -maxdepth 2 -type f \( -iname 'Containerfile' -o -iname 'Dockerfile' \))

  printf "%s" "$output_data"
}


# ---------------------------------------------------------------------------
heading "${blue}" "⚙️  Checking environment and dependencies"
# ---------------------------------------------------------------------------

if is_root ; then
  warn "Running as root, are you sure this is what you want to do? [y/N]"
  read -r response
  if [[ "$response" != "y" && "$response" != "Y" ]]; then
    error "Please re-run this script as a non-root user."
    exit 1
  fi
fi

declare container_cmd
if command -v podman >/dev/null 2>&1; then
  container_cmd="podman"
elif command -v docker >/dev/null 2>&1; then
  container_cmd="docker"
else
  error "neither podman nor docker are installed. Please install one."
  exit 1
fi

no_cache=""
if [ $# -eq 1 ] && [ "$1" == "clean" ]; then
  no_cache="--no-cache"
  printf "${blue}>> Clean building images with no cache.${nc}\n" >&2
fi

readonly container_cmd
printf "${blue}>> Using ${yellow}%s${nc} as container runtime.${nc}\n" "$container_cmd" >&2

heading "${blue}" "🔍 Discovering images"
# Default registry/prefix for image tags.
readonly image_prefix=$(basename "$project_root")
discovery_output=$(discover_images)

declare -a images_to_build=()
if [[ -n "$discovery_output" ]]; then
  readarray -t images_to_build <<< "$discovery_output"
fi

if ((${#images_to_build[@]} == 0)); then
  warn "No Container files found in immediate sub-directories. Nothing to build."
  exit 0
fi


# ---------------------------------------------------------------------------
heading "${yellow}" "📦 Starting Container Builds (${#images_to_build[@]} found)"
# ---------------------------------------------------------------------------
build_failed=0
  
temp_log_file=$(mktemp --tmpdir buildlog.XXXXXX)

for entry in "${images_to_build[@]}"; do
  IFS='|' read -r tag dir <<< "$entry"

  printf "${blue}>> Building ${yellow}%s${nc}\n" "$tag" >&2

  if run_with_spinner "${container_cmd} building" "${temp_log_file}" "${container_cmd}" build ${no_cache} -t "$tag" "$project_root/$dir"; then
    success "OK"
  else
    error "build failed"
    printf "\n${red}" >&2
    tail -n 1 "${temp_log_file}" >&2
    printf "${nc}\n" >&2
    
    warn "build log retained at: ${yellow}${temp_log_file}${nc}\n"

    build_failed=1
  fi
done

# clean up layers and images
${container_cmd} rmi $(${container_cmd} images --filter "dangling=true" -q --no-trunc) > /dev/null 2>&1 || true

if [[ "$build_failed" -eq 0 ]]; then
  heading "${green}" "📝 Summary"
  success "All images built successfully...\n"
  "${container_cmd}" images | grep "${image_prefix}/"
else
  heading "${red}" "📝 Summary"
  error "some builds failed. Please review the output and logs."
fi

exit "$build_failed"
