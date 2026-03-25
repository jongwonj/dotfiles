#!/usr/bin/env bash

show_script_info() {
  echo "basename: ${0##*/}"
  echo "dirname : $(dirname "${0}")"
  echo "pwd     : $(pwd)"
  echo ""
}

go_to_base_dir() {
  base_dir="$(cd "$(dirname "${0}")" && pwd)"
  cd "${base_dir}" || exit 1
}

is_linux() {
  [[ "$(uname)" == "Linux" ]]
}

is_wsl() {
  [[ -f /proc/version ]] && grep -qiE "microsoft|wsl" /proc/version
}

is_mac() {
  [[ "$(uname)" == "Darwin" ]]
}

is_ubuntu() {
  [[ -f /etc/os-release ]] || return 1
  (
    source /etc/os-release
    [[ "${ID}" == "ubuntu" || "${ID_LIKE}" =~ "ubuntu" ]]
  )
}

run_setup() {
  local setup_packages_script=""
  local setup_dotfiles_script=""
  local setup_args=("${@}")

  if is_linux; then
    if is_ubuntu; then
      setup_packages_script="setup_ubuntu_packages.sh"
    else
      echo "⚠️ Warning: Detected unsupported Linux distribution. Proceeding with caution."
    fi

    setup_dotfiles_script="setup_dotfiles.sh"

  elif is_mac; then
    setup_packages_script="setup_macOS_packages.sh"
    setup_dotfiles_script="setup_dotfiles.sh"

  else
    echo "❌ Error: Unsupported operating system: $(uname)"
    exit 1
  fi

  for script_name in "${setup_packages_script}" "${setup_dotfiles_script}"; do
    if [[ -n "${script_name}" ]]; then
      local found=false
      local search_paths=(
        "${base_dir}/${script_name}"
        "${base_dir}/scripts/${script_name}"
      )

      for target in "${search_paths[@]}"; do
        if [[ -f "${target}" ]]; then
          echo "🔄 Running setup script: ${script_name}"
          bash "${target}" "${setup_args[@]}"
          found=true
          break
        fi
      done

      if [[ "${found}" == "false" ]]; then
        echo "❌ Error: Could not find '${script_name}'."
        echo "   Checked locations:"
        for path in "${search_paths[@]}"; do
          echo "   - ${path}"
        done
        exit 1
      fi
    fi
  done
}

perform_reboot() {
  while true; do
    read -rp "🚀 Do you want to reboot (y/n)? " answer
    case "${answer}" in
    [Yy]*)
      if is_linux && ! is_wsl; then
        sudo reboot

      elif is_wsl; then
        wsl.exe --shutdown

      elif is_mac; then
        sudo shutdown -r now
      fi
      break
      ;;
    [Nn]*)
      echo "✅ Reboot skipped."
      break
      ;;
    *)
      echo "⚠️ Invalid input. Please enter 'y' or 'n'."
      ;;
    esac
  done
}

main() {
  show_script_info
  go_to_base_dir
  run_setup "${@}"
  perform_reboot
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "${@}"
fi
