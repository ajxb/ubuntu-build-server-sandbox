#!/bin/bash

###############################################################################
# Configure puppet with our manifests and setting for the puppet run
# Globals:
#   None
# Arguments:
#   $@
# Returns:
#   None
###############################################################################
configure_puppet() {
  echo 'Copying Puppet configuration to /etc/puppetlabs/code/environments'
  rsync -rltDogz --delete --chown=root:root "${MY_PATH}/../puppet/environments" /etc/puppetlabs/code
  if [[ $? -ne 0 ]]; then
    abort 'Failed to copy Puppet configuration'
  fi

  if [[ -e /etc/puppetlabs/puppet/hiera.yaml ]]; then
    rm -f /etc/puppetlabs/puppet/hiera.yaml
  fi
}

###############################################################################
# Install modules from the web using librarian-puppet
# Globals:
#   None
# Arguments:
#   $@
# Returns:
#   None
###############################################################################
install_modules() {
  echo 'Updating puppet modules'
  pushd /etc/puppetlabs/code/environments/production > /dev/null 2>&1
  librarian-puppet install
  if [[ $? -ne 0 ]]; then
    abort 'Failed to update puppet modules'
  fi
  popd > /dev/null 2>&1
}

###############################################################################
# Run puppet for ${HOSTNAME}
# Globals:
#   None
# Arguments:
#   $@
# Returns:
#   None
###############################################################################
run_puppet() {
  echo 'Executing puppet'
  pushd  > /dev/null 2>&1
  puppet apply /etc/puppetlabs/code/environments/production/manifests/default.pp
  if [[ $? -ne 0 ]]; then
    abort 'Failed to execute puppet'
  fi
  popd > /dev/null 2>&1
}

###############################################################################
# Parse script input for validity and configure global variables for use
# throughout the script
# Globals:
#   None
# Arguments:
#   $@
# Returns:
#   None
###############################################################################
setup_vars() {
  # Process script options
  while getopts ':h' option; do
    case "${option}" in
      h) usage ;;
      :)
        echo "Option -${OPTARG} requires an argument"
        usage
        ;;
      ?)
        echo "Option -${OPTARG} is invalid"
        usage
        ;;
    esac
  done
}

###############################################################################
# Output usage information for the script to the terminal
# Globals:
#   $0
# Arguments:
#   None
# Returns:
#   None
###############################################################################
usage() {
  local script_name
  script_name="$(basename "$0")"

  echo "usage: ${script_name} options"
  echo
  echo 'Execute puppet apply for ${HOSTNAME}.pp'
  echo
  echo 'OPTIONS:'
  echo "  -h show help information about ${script_name}"

  exit 1
}

main() {
  pushd "${MY_PATH}" > /dev/null 2>&1

  setup_vars "$@"
  check_user
  use_system_ruby
  . /etc/profile.d/puppet-agent.sh
  configure_puppet
  install_modules
  run_puppet

  popd > /dev/null 2>&1
}

echo '**** run_puppet ****'

MY_PATH="$(dirname "$0")"
MY_PATH="$(cd "${MY_PATH}" && pwd)"
readonly MY_PATH

source "${MY_PATH}/common_properties.sh"
source "${MY_PATH}/common_functions.sh"

main "$@"

echo '**** run_puppet - done ****'

exit 0
