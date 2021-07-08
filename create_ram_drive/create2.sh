#!/usr/bin/env bash
# ar18

# Prepare script environment
{
  # Script template version 2021-07-04_19:11:04
  # Make sure some modification to LD_PRELOAD will not alter the result or outcome in any way
  LD_PRELOAD_old="${LD_PRELOAD}"
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
  # Get old shell option values to restore later
  shopt -s inherit_errexit
  IFS=$'\n' shell_options=($(shopt -op))
  # Set shell options for this script
  set -o pipefail
  set -eu
  if [ ! -v ar18_parent_process ]; then
    export ar18_parent_process="$"
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

ar18.script.obtain_sudo_password

size="${1}"
# size is passed in GB, but brd needs MB
size=$((size * 1024))
set +u
mount_point="${2}"
set -u

if [ "${mount_point}" = "" ]; then
  mount_point="/mnt/ram_disk"
fi

ar18.script.execute_with_sudo umount -f "${mount_point}"
ar18.script.execute_with_sudo rm -rf "${mount_point}"
ar18.script.execute_with_sudo mkdir "${mount_point}"
ar18.script.execute_with_sudo mount -t tmpfs tmpfs "${mount_point}"
ar18.script.execute_with_sudo dd if=/dev/zero of="${mount_point}/disk0" bs=1M count="${size}"
ar18.script.execute_with_sudo losetup /dev/loop0 "${mount_point}/disk0"
ar18.script.execute_with_sudo mke2fs /dev/loop0
ar18.script.execute_with_sudo chmod 777 -R "${mount_point}"

##################################SCRIPT_END###################################
# Restore environment
{
  # Restore old shell values
  set +x
  for option in "${shell_options[@]}"; do
    eval "${option}"
  done
  # Restore LD_PRELOAD
  LD_PRELOAD="${LD_PRELOAD_old}"
  # Restore PWD
  cd "${ar18_pwd_map["${script_path}"]}"
}
# Return or exit depending on whether the script was sourced or not
{
  if [ "${ar18_sourced_map["${script_path}"]}" = "1" ]; then
    return "${ar18_exit_map["${script_path}"]}"
  else
    exit "${ar18_exit_map["${script_path}"]}"
  fi
}
