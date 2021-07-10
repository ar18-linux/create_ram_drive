#!/usr/bin/env bash
# ar18

# Prepare script environment
{
  # Script template version 2021-07-10_11:24:30
  # Get old shell option values to restore later
  shopt -s inherit_errexit
  IFS=$'\n' shell_options=($(shopt -op))
  set +x
  # Set shell options for this script
  set -o pipefail
  set -e
  # Make sure some modification to LD_PRELOAD will not alter the result or outcome in any way
  set +u
  LD_PRELOAD_old="${LD_PRELOAD}"
  set -u
  LD_PRELOAD=
  # Determine the full path of the directory this script is in
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
  script_path="${script_dir}/$(basename "${0}")"
  #Set PS4 for easier debugging
  export PS4='\e[35m${BASH_SOURCE[0]}:${LINENO}: \e[39m'
  # Determine if this script was sourced or is the parent script
  if [ ! -v ar18_sourced_map ]; then
    declare -A -g ar18_sourced_map
  fi
  if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    ar18_sourced_map["${script_path}"]=1
  else
    ar18_sourced_map["${script_path}"]=0
  fi
  # Initialise exit code
  if [ ! -v ar18_exit_map ]; then
    declare -A -g ar18_exit_map
  fi
  ar18_exit_map["${script_path}"]=0
  # Save PWD
  if [ ! -v ar18_pwd_map ]; then
    declare -A -g ar18_pwd_map
  fi
  ar18_pwd_map["${script_path}"]="${PWD}"
  if [ ! -v ar18_parent_process ]; then
    export ar18_parent_process="$$"
  fi
  # Get import module
  if [ ! -v ar18.script.import ]; then
    mkdir -p "/tmp/${ar18_parent_process}"
    cd "/tmp/${ar18_parent_process}"
    curl -O https://raw.githubusercontent.com/ar18-linux/ar18_lib_bash/master/ar18_lib_bash/script/import.sh > /dev/null 2>&1 && . "/tmp/${ar18_parent_process}/import.sh"
    cd "${ar18_pwd_map["${script_path}"]}"
  fi
}
#################################SCRIPT_START##################################

ar18.script.import ar18.script.obtain_sudo_password
ar18.script.import ar18.script.execute_with_sudo
ar18.script.import ar18.script.version_check

ar18.script.version_check

size="${1}"
# size is passed in GB, but brd needs KB
size=$((size * 1024000))
set +u
mount_point="${2}"
set -u

if [ "${mount_point}" = "" ]; then
  mount_point="/mnt/ram_disk"
fi

ar18.script.obtain_sudo_password

ar18.script.execute_with_sudo modprobe brd rd_nr=1 rd_size="${size}" max_part=1

set +e
echo 'type=83' | ar18.script.execute_with_sudo sfdisk "/dev/ram0"
set -e
ar18.script.execute_with_sudo mkfs.ext4 "/dev/ram0"

ar18.script.execute_with_sudo mkdir -p "${mount_point}"
ar18.script.execute_with_sudo mount "/dev/ram0" "${mount_point}"

##################################SCRIPT_END###################################
# Restore environment
{
  set +x
  # Restore LD_PRELOAD
  LD_PRELOAD="${LD_PRELOAD_old}"
  # Restore PWD
  cd "${ar18_pwd_map["${script_path}"]}"
  # Restore old shell values
  for option in "${shell_options[@]}"; do
    eval "${option}"
  done
}
# Return or exit depending on whether the script was sourced or not
{
  if [ "${ar18_sourced_map["${script_path}"]}" = "1" ]; then
    return "${ar18_exit_map["${script_path}"]}"
  else
    exit "${ar18_exit_map["${script_path}"]}"
  fi
}
