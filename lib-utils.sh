# Define ANSI color codes/symbols
readonly green='\033[0;32m'
readonly red='\033[0;31m'
readonly yellow='\033[0;33m'
readonly blue='\033[0;34m'
readonly nc='\033[0m' # No Color
readonly check_mark="${green}✔${nc}"
readonly cross_mark="${red}✘${nc}"

# --- Utility Functions ---

command_check() {
  local cmd

  for cmd in "$@"; do
    if ! command -v "$cmd" &>/dev/null; then
      error "required command not found: $cmd"
      return 1
    fi
  done
  return 0
}

is_root() {
  [[ "$EUID" -eq 0 ]]
}

no_root() {
  is_root && {
    error "this script should not be run as root. Please run as a regular user without 'sudo'."
    return 1
  }
  return 0
}

needs_root() {
  is_root || {
    error "this script must be run as root. Please rerun with 'sudo' or as root user."
    return 1
  }
  return 0
}

run_with_spinner() {
  local description="$1"
  local temp_log_file="$2"
  shift 2

  printf "${blue}⟳${nc} ${description}...  " >&2
  
  "$@" >> "$temp_log_file" 2>&1 &
  local pid=$!
  local delay=0.1
  local spin_chars=($'\\' '|' '/' '-')
  local i=0

  while kill -0 "$pid" 2>/dev/null; do
    printf "\b${blue}%s${nc}" "${spin_chars[i++ % ${#spin_chars[@]}]}" >&2
    sleep "$delay"
  done

  printf "\b" >&2

  wait "$pid"
  return $?
}

heading() {
  local colour="$1"
  local title="$2"

  printf "\n${colour}-------------------------------------------------------------------${nc}\n" >&2
  printf "$title" >&2
  printf "\n${colour}-------------------------------------------------------------------${nc}\n\n" >&2
}

error() {
  local message="$1"
  printf "${cross_mark}${red} Error:${nc} ${message}\n" >&2
}

warn() {
  local message="$1"
  printf "${yellow}⚠️  ${nc} ${message}\n" >&2
}

success() {
  local message="$1"
  printf "${check_mark}  ${message}\n" >&2
}

cleanup() {
  local temp_files=("$@")

  if ((${#temp_files[@]} > 0)); then
    rm -f "${temp_files[@]}" 2>/dev/null || true
  fi
}
