#!/usr/bin/env bash

show_script_info() {
  echo "basename: ${0##*/}"
  echo "dirname : $(dirname "${0}")"
  echo "pwd     : $(pwd)"
  echo ""
}

is_linux() {
  [[ "$(uname)" == "Linux" ]]
}

is_mac() {
  [[ "$(uname)" == "Darwin" ]]
}

initialize_variables() {
  dotfiles_base="${HOME}/.dotfiles"
  backup_dir="${HOME}/.local/share/backups"
  mkdir -pv "${backup_dir}"
}

find_and_move_to_dotfiles_root() {
  local target_file="install.sh"
  local curr_dir
  curr_dir="$(cd "$(dirname "$0")" && pwd)"

  while [ "${curr_dir}" != "/" ]; do
    if [ -f "${curr_dir}/${target_file}" ]; then
      echo "Found '${target_file}' in: ${curr_dir}"
      cd "${curr_dir}" || {
        echo "❌ Error: Unable to move to directory '${curr_dir}'."
        return 1
      }
      dotfiles_root="${curr_dir}"
      return 0
    fi
    curr_dir="$(dirname "${curr_dir}")"
  done

  echo "❌ Error: '${target_file}' not found in any parent directories."
  return 1
}

create_dir() {
  mkdir -pv "${1}"
}

backup_if_exists() {
  local target_path="${1}"
  if [ -e "${target_path}" ] && [ ! -L "${target_path}" ]; then
    echo "🔄 Backing up existing file/directory: ${target_path}"
    mv -fv "${target_path}" "${backup_dir}/${target_path##*/}.$(date +"%Y%m%d_%H%M%S").bak"
  fi
}

create_symlink() {
  local source_path="${1}"
  local target_path="${2}"

  if [ ! -e "${source_path}" ]; then
    echo "❌ Error: Source file/directory not found: ${source_path}"
    return 1
  fi

  if [ -L "${target_path}" ] && [ "$(readlink "${target_path}")" = "${source_path}" ]; then
    echo "✅ Symlink already exists and is correct: ${target_path}"
    return 0
  fi

  backup_if_exists "${target_path}"

  if is_linux; then
    ln --force --symbolic --verbose "${source_path}" "${target_path}"
  elif is_mac; then
    ln -fsv "${source_path}" "${target_path}"
  fi
}

link_recursive() {
  local src_dir="${1}"
  local dest_dir="${2}"

  create_dir "${dest_dir}"

  shopt -s dotglob nullglob

  for item_path in "${src_dir}"/*; do
    local item_name="${item_path##*/}"
    local src_item="${src_dir}/${item_name}"
    local dest_item="${dest_dir}/${item_name}"

    if [[ "${item_name}" == ".DS_Store" ]]; then
      continue
    fi

    if [ -d "${src_item}" ]; then
      link_recursive "${src_item}" "${dest_item}"
    else
      create_symlink "${src_item}" "${dest_item}"
    fi
  done

  shopt -u dotglob nullglob
}

copy_files() {
  local srcs=("${@:1:$#-1}")
  local dest="${@: -1}"

  if is_linux; then
    cp --force --archive --verbose "${srcs[@]}" "${dest}"

  elif is_mac; then
    cp -RXv "${srcs[@]}" "${dest}"
  fi
}

backup_and_copy_dotfiles() {
  if [ "${dotfiles_root}" != "${dotfiles_base}" ]; then
    if [ -d "${dotfiles_base}" ]; then
      create_dir "${backup_dir}"
      mv -fv "${dotfiles_base}" "${backup_dir}/dotfiles_old_$(date +"%Y%m%d_%H%M%S")"
    fi

    if command -v rsync &>/dev/null; then
      rsync -av --exclude='.git' --exclude='.github' "${dotfiles_root}/" "${dotfiles_base}/"
    else
      create_dir "${dotfiles_base}"
      shopt -s dotglob
      for item in "${dotfiles_root}"/*; do
        local item_name="${item##*/}"
        if [[ "${item_name}" == "." || "${item_name}" == ".." || "${item_name}" == ".git" || "${item_name}" == ".github" ]]; then
          continue
        fi

        copy_files "${item}" "${dotfiles_base}"
      done
      shopt -u dotglob
    fi

    cd "${dotfiles_base}"
  fi
}

symlink_dotfiles() {
  local repo_home_dir="${dotfiles_base}/home"
  if [ -d "${repo_home_dir}" ]; then
    link_recursive "${repo_home_dir}" "${HOME}"
  fi

  local repo_config_dir="${dotfiles_base}/config"
  if [ -d "${repo_config_dir}" ]; then
    link_recursive "${repo_config_dir}" "${HOME}/.config"
  fi

  local vscode_settings_src="${repo_config_dir}/Code/User/settings.json"
  if [ -f "${vscode_settings_src}" ] && is_mac; then
    local vscode_target_dir="${HOME}/Library/Application Support/Code/User"
    create_dir "${vscode_target_dir}"
    create_symlink "${vscode_settings_src}" "${vscode_target_dir}/settings.json"
  fi
}

main() {
  show_script_info
  initialize_variables
  find_and_move_to_dotfiles_root

  echo ""
  echo "🚀 Setup dotfiles start"
  printf "%0.s-" {1..60}
  echo ""

  backup_and_copy_dotfiles
  symlink_dotfiles

  echo ""
  printf "%0.s-" {1..60}
  printf "\n✅ Setup dotfiles done!\n"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "${@}"
fi
