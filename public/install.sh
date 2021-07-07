#!/bin/sh

# DEFINES: COLORS
RED='\033[0;31m'
GREEN='\033[1;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

# DEFINES: SPINNER ELEMENTS

CL="\e[2K"
SPINNER="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"

# DEFINES: MESSAGES
USE_NPM="consider installation using \"npm\""
UNSUPPORTED_CPU="${RED}Unsupported CPU architecture, $USE_NPM${NC}"
UNSUPPORTED_OS="${RED}Unsupported OS detected, $USE_NPM${NC}"
NO_ROOT="${YELLOW}Running in non-root mode, run as root if you encounter any permission errors${NC}"
NO_NODE="${YELLOW}Node.js not found, downloading a packed version of please${NC}"
DONE="${GREEN}Installation finished, you can now use the please command!${NC}"
NO_RELEASE="${RED}Cannot fetch the latest release tag from GitHub${NC}"
CANNOT_FETCH="${RED}Installation failed, cannot access the download url${NC}"
NPM_INSTALL="Installing 'please' using NPM"
FETCHING="Fetching 'please' from GitHub"

# DEFINES: VARIABLES
GH_RELEASES="https://api.github.com/repos/pleasecmd/please/releases"

# Check if we're on Alpine Linux
check_alpine() {
  return ! $(cat /etc/os-release | grep "NAME=" | grep -ic "Alpine")
}

# Get OS class, or unknown
get_os() {
  if $(check_alpine); then
    echo "alpine"
  elif [ "$(uname)" == "Darwin" ]; then
    echo "macos"
  elif [ "$(uname)" == "Linux" ]; then
    echo "linux"
  else
    echo "unknown"
  fi
}

# Get CPU arch, or unknown
get_arch() {
  MACHINE=$(uname -m)
  if [ "$MACHINE" == "aarch64" ]; then
    echo "arm64"
  elif [ "$MACHINE" == "x86_64" ]; then
    echo "x64"
  else
    echo "unknown"
  fi
}

# Check if the script is running as root
check_root() {
  if [ "$EUID" -ne 0 ]; then
    echo "$NO_ROOT"
  fi
}

spinner() {
  msg=$1
  while :; do
    jobs %1 > /dev/null 2>&1
    [ $? = 0 ] || {
      printf "${CL}"
      break
    }
    i=0
    while [ "$i" -ne 9 ]; do
      i=$(($i+1))
      sleep 0.05
      printf "${CL}${SPINNER:$i:1} ${msg}\r"
    done
  done
}

# Install using npm
npm_install() {
  npm i --silent --no-progress -g @please.dev/cli &> /dev/null
}

# Fetch release from GitHub
fetch_release() {
  URL=$1
  curl -s "$URL" -o /usr/bin/local/please 2>&1 > /dev/null
}

# Install the latest please pack from GitHub
pack_install() {
  # Check for OS and display an error if it's not supported
  OS=$(get_os)
  if [ "$OS" == "unknown" ]; then
    echo "$UNSUPPORTED_CPU"
    exit 1
  fi

  # Check for CPU arch and display an error if it's not supported
  ARCH=$(get_arch)
  if [ "$ARCH" == "unknown" ]; then
    echo "$UNSUPPORTED_OS"
    exit 1
  fi

  # Get the latest release name from GitHub, display an error on failure
  LATEST=$(curl -s $GH_RELEASES | grep tag_name | head -1 | cut -d '"' -f 4 | tr -d v)
  FAILED=$?
  if [ $FAILED ]; then
    echo $NO_RELEASE
    exit
  fi

  # Download the latest release from GitHub, display an error on failure
  URL="https://get.please.devz/$LATEST/$OS/$ARCH"
  fetch_payload "$URL" & spinner "$FETCHING"
  FAILED=$?
  if [ $FAILED ]; then
    echo $CANNOT_FETCH
    exit 1
  fi

  # Mark the downloaded file as executable
  chmod +x /usr/bin/local/please
}

# Main installation command
install_please() {
  check_root
  # If npm exists, we use it to install please
  if [ -x "$(command -v npm)" ]; then
    npm_install & spinner "$NPM_INSTALL"
  # Otherwise we'll download a packed version
  else
    echo "$NO_NODE"
    pack_install
  fi
  echo "$DONE"
}

install_please