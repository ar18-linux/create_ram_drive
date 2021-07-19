#!/usr/bin/env bash
# ar18

# Prepare script environment
{
  # Script template version 2021-07-14_00:22:16
  script_dir_temp="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
  script_path_temp="${script_dir_temp}/$(basename "${BASH_SOURCE[0]}")"
  # Get old shell option values to restore later
  if [ ! -v ar18_old_shopt_map ]; then
    declare -A -g ar18_old_shopt_map
  fi
  shopt -s inherit_errexit
  ar18_old_shopt_map["${script_path_temp}"]="$(shopt -op)"
  set +x
  # Set shell options for this script
  set -e
  set -E
  set -o pipefail
  set -o functrace
}

function stacktrace(){
  echo "STACKTRACE"
  local size
  size="${#BASH_SOURCE[@]}"
  local idx
  idx="$((size - 2))"
  while [ "${idx}" -ge "1" ]; do
    caller "${idx}"
    ((idx--))
  done
}

function restore_env(){
  local exit_script_path
  exit_script_path="${script_path}"
  # Restore PWD
  cd "${ar18_pwd_map["${exit_script_path}"]}"
  # Restore ar18_extra_cleanup
  eval "${ar18_sourced_return_map["${exit_script_path}"]}"
  # Restore script_dir and script_path
  script_dir="${ar18_old_script_dir_map["${exit_script_path}"]}"
  script_path="${ar18_old_script_path_map["${exit_script_path}"]}"
  # Restore LD_PRELOAD
  LD_PRELOAD="${ar18_old_ld_preload_map["${exit_script_path}"]}"
  # Restore old shell values
  IFS=$'\n' shell_options=(echo ${ar18_old_shopt_map["${exit_script_path}"]})
  for option in "${shell_options[@]}"; do
    eval "${option}"
  done
}

function ar18_return_or_exit(){
  set +x
  local path
  path="${1}"
  local ret
  set +u
  ret="${2}"
  set -u
  if [ "${ret}" = "" ]; then
    ret="${ar18_exit_map["${path}"]}"
  fi
  if [ "${ar18_sourced_map["${path}"]}" = "1" ]; then
    export ar18_exit="return ${ret}"
  else
    export ar18_exit="exit ${ret}"
  fi
}

function clean_up() {
  rm -rf "/tmp/${ar18_parent_process}"
  if type ar18_extra_cleanup > /dev/null 2>&1; then
    ar18_extra_cleanup
  fi
}
trap clean_up SIGINT SIGHUP SIGQUIT SIGTERM EXIT

function err_report() {
  local path="${1}"
  local lineno="${2}"
  local msg="${3}"
  RED="\e[1m\e[31m"
  NC="\e[0m" # No Color
  stacktrace
  printf "${RED}ERROR ${path}:${lineno}\n${msg}${NC}\n"
}
trap 'err_report "${BASH_SOURCE[0]}" ${LINENO} "${BASH_COMMAND}"' ERR

{
  # Make sure some modification to LD_PRELOAD will not alter the result or outcome in any way
  if [ ! -v ar18_old_ld_preload_map ]; then
    declare -A -g ar18_old_ld_preload_map
  fi
  if [ ! -v LD_PRELOAD ]; then
    LD_PRELOAD=""
  fi
  ar18_old_ld_preload_map["${script_path_temp}"]="${LD_PRELOAD}"
  LD_PRELOAD=""
  # Save old script_dir variable
  if [ ! -v ar18_old_script_dir_map ]; then
    declare -A -g ar18_old_script_dir_map
  fi
  set +u
  if [ ! -v script_dir ]; then
    script_dir="${script_dir_temp}"
  fi
  ar18_old_script_dir_map["${script_path_temp}"]="${script_dir}"
  set -u
  # Save old script_path variable
  if [ ! -v ar18_old_script_path_map ]; then
    declare -A -g ar18_old_script_path_map
  fi
  set +u
  if [ ! -v script_path ]; then
    script_path="${script_path_temp}"
  fi
  ar18_old_script_path_map["${script_path_temp}"]="${script_path}"
  set -u
  # Determine the full path of the directory this script is in
  script_dir="${script_dir_temp}"
  script_path="${script_path_temp}"
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
    unset import_map
    export ar18_parent_process="$$"
  fi
  # Local return trap for sourced scripts so that each sourced script 
  # can have their own return trap
  if [ ! -v ar18_sourced_return_map ]; then
    declare -A -g ar18_sourced_return_map
  fi
  if type ar18_extra_cleanup > /dev/null 2>&1 ; then
    ar18_extra_cleanup_temp="$(type ar18_extra_cleanup)"
    ar18_extra_cleanup_temp="$(echo "${ar18_extra_cleanup_temp}" | sed -E "s/^.+is a function\s*//")"
  else
    ar18_extra_cleanup_temp=""
  fi
  ar18_sourced_return_map["${script_path}"]="${ar18_extra_cleanup_temp}"
  function local_return_trap(){
    if [ "${ar18_sourced_map["${script_path}"]}" = "1" ] \
    && [ "${FUNCNAME[1]}" = "ar18_return_or_exit" ]; then
      if type ar18_extra_cleanup > /dev/null 2>&1; then
        ar18_extra_cleanup
      fi
      restore_env
    fi
  }
  trap local_return_trap RETURN
  # Get import module
  if [ ! -v ar18_script_import ]; then
    mkdir -p "/tmp/${ar18_parent_process}"
    old_cwd="${PWD}"
    cd "/tmp/${ar18_parent_process}"
    curl -O https://raw.githubusercontent.com/ar18-linux/ar18_lib_bash/master/ar18_lib_bash/script/import.sh >/dev/null 2>&1 && . "/tmp/${ar18_parent_process}/import.sh"
    export ar18_script_import
    cd "${old_cwd}"
  fi
}
#################################SCRIPT_START##################################

echo "create2 <size GB> [mountpoint=/mnt/ram_disk]"

ar18.script.import ar18.script.obtain_sudo_password
ar18.script.import ar18.script.execute_with_sudo
ar18.script.import ar18.script.version_check

ar18.script.version_check "${@}"

ar18.script.obtain_sudo_password

size="${1}"
# size is passed in GB, but brd needs MB
size=$((size * 1024))
set +u
mount_point="${2}"
set -u

mount_point_temp="/mnt/ram_disk_file"

if [ "${mount_point}" = "" ]; then
  mount_point="/mnt/ram_disk"
fi
loop_no="12345"
#set +e
#ar18.script.execute_with_sudo umount -f "/dev/loop0"
if mountpoint -q "${mount_point}"; then
  ar18.script.execute_with_sudo umount -lf "${mount_point}"
  #ar18.script.execute_with_sudo umount -f "${mount_point}"
fi
if mountpoint -q "${mount_point_temp}"; then
  ar18.script.execute_with_sudo umount -lf "${mount_point_temp}"
  #ar18.script.execute_with_sudo umount -f "${mount_point_temp}"
fi
#set -e
if losetup -a | grep "/dev/loop${loop_no}"; then
  ar18.script.execute_with_sudo losetup -d "/dev/loop${loop_no}"
fi
ar18.script.execute_with_sudo rm -rf "${mount_point_temp}"
ar18.script.execute_with_sudo rm -rf "${mount_point}"
ar18.script.execute_with_sudo mkdir "${mount_point_temp}"
ar18.script.execute_with_sudo mkdir "${mount_point}"
ar18.script.execute_with_sudo mount -o size="${size}M"  -t tmpfs tmpfs "${mount_point_temp}"
echo "Preparing ram disk... (${size}MB)"
ar18.script.execute_with_sudo dd if="/dev/zero" of="${mount_point_temp}/disk0" bs=1M count="${size}" status=progress
ar18.script.execute_with_sudo losetup "/dev/loop${loop_no}" "${mount_point_temp}/disk0"
ar18.script.execute_with_sudo mke2fs "/dev/loop${loop_no}"
ar18.script.execute_with_sudo mount "/dev/loop${loop_no}" "${mount_point}"
ar18.script.execute_with_sudo chmod 777 -R "${mount_point}"

##################################SCRIPT_END###################################
set +x
ar18_return_or_exit "${script_path}" && eval "${ar18_exit}"
