#!/usr/bin/env bash

show_script_info() { # {{{
  echo "basename: ${0##*/}"
  echo "dirname : $(dirname "${0}")"
  echo "pwd     : $(pwd)"
  echo ""
} # }}}

# Detect functions {{{
is_wsl() {
  [[ -f /proc/version ]] && grep -qiE "microsoft|wsl" /proc/version
}

is_ubuntu() {
  [[ -f /etc/os-release ]] || return 1
  (
    source /etc/os-release
    [[ "${ID}" == "ubuntu" || "${ID_LIKE}" =~ "ubuntu" ]]
  )
}

is_nvidia_hardware_present() {
  lspci | grep -qi "nvidia"
}

is_nvidia_driver_ready() {
  if lsmod | grep -qE "^nvidia"; then
    return 0
  elif dpkg -l | grep -qi "nvidia-driver"; then
    return 0
  fi
  return 1
}
# }}}

initialize_flags() { # {{{
  ENABLE_NVIDIA=1
  ENABLE_WAYLAND_ENV=1
  ENABLE_HANGUL_KEYMAP=1
  ENABLE_CHANGE_SHELL=1
  ENABLE_SYSTEM_UPGRADE=1
} # }}}

parse_args() { # {{{
  local arg
  for arg in "${@}"; do
    case "${arg}" in
    --safe)
      ENABLE_NVIDIA=0
      ENABLE_WAYLAND_ENV=0
      ENABLE_HANGUL_KEYMAP=0
      ENABLE_CHANGE_SHELL=0
      ENABLE_SYSTEM_UPGRADE=0
      ;;
    --no-nvidia)
      ENABLE_NVIDIA=0
      ;;
    --no-wayland-env)
      ENABLE_WAYLAND_ENV=0
      ;;
    --no-hangul-keymap)
      ENABLE_HANGUL_KEYMAP=0
      ;;
    --no-change-shell)
      ENABLE_CHANGE_SHELL=0
      ;;
    --no-system-upgrade)
      ENABLE_SYSTEM_UPGRADE=0
      ;;
    *)
      echo "❌ Error: Unknown option: ${arg}"
      echo "Supported options: --safe --no-nvidia --no-wayland-env --no-hangul-keymap --no-change-shell --no-system-upgrade"
      exit 1
      ;;
    esac
  done
} # }}}

keep_sudo_alive() { # {{{
  sudo -v
  while true; do
    sudo -n true 2>/dev/null
    sleep 30
  done &

  readonly SUDO_KEEP_ALIVE_PID=$!
} # }}}

install_package() { # {{{
  update_cache_if_needed() {
    local -r stamp_file="/var/lib/apt/periodic/update-success-stamp"
    local last_update=0

    if [[ -f "${stamp_file}" ]]; then
      last_update=$(stat -c %Y "${stamp_file}" 2>/dev/null || echo 0)
    fi

    local now
    now=$(date +%s)
    local -r interval=$((86400 * 7))

    if ((now - last_update > interval)); then
      echo "🔄 Updating APT package cache..."

      if sudo apt-get update; then
        sudo mkdir -p "$(dirname "${stamp_file}")"
        sudo touch "${stamp_file}"
      else
        echo "⚠️ Failed to update APT cache. Proceeding anyway..."
      fi
    fi
  }

  local -r pkgs=("${@}")
  local valid_pkgs=()

  update_cache_if_needed

  local pkg
  for pkg in "${pkgs[@]}"; do
    if apt-cache show "${pkg}" >/dev/null 2>&1; then
      valid_pkgs+=("${pkg}")
    else
      echo "⚠️ Skipping: ${pkg} (Not found in repository)"
    fi
  done

  if [[ ${#valid_pkgs[@]} -gt 0 ]]; then
    sudo \
      DEBIAN_FRONTEND=noninteractive \
      apt-get install \
      -o Dpkg::Options::="--force-confdef" \
      -o Dpkg::Options::="--force-confold" \
      -o Acquire::Queue-Mode=access \
      -o Acquire::Retries=5 \
      --ignore-missing \
      --fix-missing \
      --no-install-recommends \
      --yes \
      "${valid_pkgs[@]}"
  fi
} # }}}

install_basic_packages() { # {{{
  sudo apt-get update -y && sudo apt-get upgrade -y

  install_package \
    sudo build-essential coreutils util-linux \
    systemd-resolved ufw network-manager systemd iptables \
    dnsutils tcpdump \
    git curl wget gdebi \
    bash zsh tmux \
    language-pack-ko ibus-hangul \
    exfatprogs ntfs-3g btrfs-progs \
    clang lldb clang-format clangd universal-ctags \
    python3-full python3-pip python3-venv pipx \
    zip unzip 7zip-standalone \
    wl-clipboard xclip x11-apps \
    tree btop entr jq ffmpeg mat2 fzf \
    bat git-delta eza fd-find ripgrep zoxide \
    poppler-utils imagemagick \
    lazygit

  if ! is_wsl; then
    install_package \
      smplayer alsa-utils alacritty
  fi

  install_neovim() {
    # Add export PATH="$PATH:/opt/nvim-linux-x86_64/bin" to ~/.zshrc
    if command -v nvim &>/dev/null; then
      echo "✅ neovim is already installed"
      return 0
    fi

    local -r arch_type=$(uname -m)
    if [[ "${arch_type}" == "x86_64" ]]; then
      local -r download_dir="${HOME}/Downloads"
      mkdir -pv "${download_dir}"
      curl -fLo "${download_dir}/nvim-linux-x86_64.tar.gz" \
        https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
      sudo rm -rf /opt/nvim-linux-x86_64
      sudo tar -C /opt -xzf "${download_dir}/nvim-linux-x86_64.tar.gz"

      sudo ln -sf "/opt/nvim-linux-x86_64/bin/nvim" /usr/local/bin/nvim
    else
      echo "❌ Unsupported Linux architecture: ${arch_type}"
      return 1
    fi
  }
  install_neovim

  install_lazygit() {
    if command -v lazygit &>/dev/null; then
      echo "✅ Lazygit is already installed"
      return 0
    fi

    local -r arch_type=$(uname -m)
    if [[ "${arch_type}" == "x86_64" ]]; then
      local -r download_dir="${HOME}/Downloads"
      mkdir -pv "${download_dir}"
      LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | \grep -Po '"tag_name": *"v\K[^"]*')
      curl -fLo "${download_dir}/lazygit.tar.gz" "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
      # tar -xf [Archive] -C [Destination] [Target]
      tar -xf "${download_dir}/lazygit.tar.gz" -C "${download_dir}" lazygit
      sudo install "${download_dir}/lazygit" -D -t /usr/local/bin/
    else
      echo "❌ Unsupported Linux architecture: ${arch_type}"
      return 1
    fi
  }
  install_lazygit

  install_zsh_plugins() {
    local -r zsh_dir="${HOME}/.zsh"
    mkdir -p "${zsh_dir}"

    local -rA plugins=(
      ["zsh-autosuggestions"]="https://github.com/zsh-users/zsh-autosuggestions"
      ["zsh-completions"]="https://github.com/zsh-users/zsh-completions"
      ["zsh-syntax-highlighting"]="https://github.com/zsh-users/zsh-syntax-highlighting"
    )

    local name
    for name in "${!plugins[@]}"; do
      local target="${zsh_dir}/${name}"
      if [[ ! -d "${target}" ]]; then
        echo "🔄 Cloning ${name}..."
        git clone --depth 1 "${plugins[$name]}" "${target}"
      else
        echo "✅ Skipping: ${name} (Already exists)"
      fi
    done
  }
  install_zsh_plugins

  :
} # }}}

setup_nvidia() { # {{{
  if ! is_nvidia_hardware_present; then
    return 0
  fi

  install_ubuntu_nvidia_drivers() {
    if ! lsmod | grep -qE "^nvidia"; then
      if command -v ubuntu-drivers &>/dev/null; then
        echo "🔄 Installing Canonical NVIDIA drivers..."
        sudo env DEBIAN_FRONTEND=noninteractive ubuntu-drivers autoinstall
      fi
      install_package nvtop
    fi
  }

  enable_nvidia_kms() {
    local -r grub_file="/etc/default/grub"
    local -r kms_param="nvidia-drm.modeset=1"

    if ! grep -q "${kms_param}" "${grub_file}"; then
      echo "🔄 Configuring NVIDIA KMS..."
      sudo sed -i -E "s/^(GRUB_CMDLINE_LINUX_DEFAULT=\"[^\"]*)(\")/\1 ${kms_param}\2/" "${grub_file}"
      sudo update-grub
    fi
  }

  install_ubuntu_nvidia_drivers
  enable_nvidia_kms
} # }}}

make_default_directories() { # {{{
  mkdir -pv ~/Downloads
  mkdir -pv ~/Documents
} # }}}

make_RALT_to_HNGL() { # {{{
  if is_wsl; then
    return 0
  fi

  HNGL_X11() {
    local -r target_file="/usr/share/X11/xkb/keycodes/evdev"

    if ! [ -f "${target_file}" ]; then
      return 0
    fi
    if grep -q "^[[:space:]]*<HNGL>[[:space:]]*=[[:space:]]*108;" "${target_file}"; then
      return 0
    fi

    sudo bash <<SUDO_SCRIPT
  cp "${target_file}" "${target_file}.$(date +%Y%m%d-%H%M%S).bak"
  # 1. Comment out '<RALT> = 108;' and add '<HNGL> = 108;' right below it
  sed -i '/^[[:space:]]*<RALT>[[:space:]]*=[[:space:]]*108;/c\// <RALT> = 108;\n<HNGL> = 108;' "${target_file}"
  # 2. Comment out the existing '<HNGL> = 130;' line
  sed -i 's/^[[:space:]]*<HNGL>[[:space:]]*=[[:space:]]*130;/ \/\/ <HNGL> = 130;/g' "${target_file}"
SUDO_SCRIPT
  }

  HNGL_Wayland() {
    if command -v gsettings &>/dev/null; then
      local -r schema="org.gnome.desktop.input-sources"
      local -r key="xkb-options"
      local -r option="'korean:ralt_hangul'"

      # 1. Get current XKB options
      local current_value
      current_value=$(gsettings get "${schema}" "${key}")

      # 2. Check if the option is already active
      if [[ "${current_value}" == *"${option}"* ]]; then
        echo "✅ Right Alt is already mapped to Hangul (Wayland/X11)."
        return 0
      fi

      echo "🔄 Remapping Right Alt to Hangul for Wayland/X11..."

      # 3. Append the option safely
      if [[ "${current_value}" == "@as []" ]] || [[ "${current_value}" == "[]" ]]; then
        # If empty, set it directly
        gsettings set "${schema}" "${key}" "['korean:ralt_hangul']"
      else
        # If not empty, append it (removing the closing bracket ']')
        # e.g., ['caps:escape'] -> ['caps:escape', 'korean:ralt_hangul']
        local new_value="${current_value%]}"
        new_value="${new_value}, ${option}]"
        gsettings set "${schema}" "${key}" "${new_value}"
      fi
    else
      echo "⚠️ 'gsettings' not found. Skipping key remap."
    fi
  }

  HNGL_X11
  HNGL_Wayland

  # How to rollback
  # --------------------------------------------------------
  # **X11**
  # Step 1) Check if backup files exist
  # ls /usr/share/X11/xkb/keycodes/evdev.*.bak
  # Step 2)
  # sudo cp /usr/share/X11/xkb/keycodes/evdev.{**backup-date**}.bak /usr/share/X11/xkb/keycodes/evdev
  # Step 3)
  # sudo reboot
  #
  # **Wayland**
  # Step 1) Check current state
  # gsettings get org.gnome.desktop.input-sources xkb-options
  # Step 2)
  # gsettings set org.gnome.desktop.input-sources xkb-options "[]"
  # Step 3)
  # sudo reboot
} # }}}

install_node() { # {{{
  if command -v node &>/dev/null; then
    return 0
  fi

  # Manually load nvm to use it immediately within this script
  if [ -z "$NVM_DIR" ] || [ ! -d "$NVM_DIR" ]; then
    export NVM_DIR="${HOME}/.nvm"
  fi

  if [ -s "${NVM_DIR}/nvm.sh" ]; then
    \. "${NVM_DIR}/nvm.sh"
  else
    echo "🔄 Installing nvm to ${NVM_DIR}..."
    mkdir -p "$NVM_DIR"
    # Install nvm without modifying the profile file (prevent auto-appending to .zshrc)
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | PROFILE=/dev/null bash

    [ -s "${NVM_DIR}/nvm.sh" ] && \. "${NVM_DIR}/nvm.sh"
  fi

  if command -v nvm &>/dev/null; then
    nvm install --lts
    nvm alias default 'lts/*'
    nvm use default
    npm install -g npm@latest
  else
    echo "❌ Error: Failed to install or load nvm."
    return 1
  fi

  if command -v npm &>/dev/null; then
    corepack enable

    npm install -g \
      tree-sitter-cli

    npm install -g \
      @biomejs/biome \
      prettier

    npm install -g \
      typescript \
      typescript-language-server
  else
    echo "⚠️ npm not found. Skipping JavaScript-based tools."
  fi
} # }}}

install_global_packages() { # {{{
  if ! command -v deno &>/dev/null; then
    curl -fsSL https://deno.land/install.sh | sh
    export DENO_INSTALL="$HOME/.deno"
    export PATH="$DENO_INSTALL/bin:$PATH"
  fi

  if ! command -v bun &>/dev/null; then
    curl -fsSL https://bun.com/install | bash
    export BUN_INSTALL="$HOME/.bun"
    export PATH="$BUN_INSTALL/bin:$PATH"
  fi

  if ! command -v uv &>/dev/null; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="${HOME}/.local/bin:${HOME}/.cargo/bin:${PATH}"
  fi

  if command -v uv &>/dev/null; then
    uv python install
    uv tool install ruff
    uv tool install ty
    uv tool install pre-commit
    uv tool install "yt-dlp[default]" --with yt-dlp-ejs
  fi

  if ! command -v starship &>/dev/null; then
    curl -sS https://starship.rs/install.sh | sh
  fi
} # }}}

install_rust() { # {{{
  echo "🔄 Checking Rust build dependencies..."
  install_package pkg-config libssl-dev

  if ! command -v rustup &>/dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  fi

  . "${HOME}/.cargo/env"

  rustup component add rust-analyzer rustfmt clippy

  install_cargo_bin() {
    if ! command -v "${1}" &>/dev/null; then
      echo "Installing ${1} via cargo..."
      cargo install "${2}"
    else
      echo "✅ ${1} is already installed. Skipping..."
    fi
  }

  install_cargo_bin "cargo-watch" "cargo-watch"
  # install_cargo_bin "bat" "bat"
  # install_cargo_bin "delta" "git-delta"
  # install_cargo_bin "eza" "eza"
  # install_cargo_bin "fd" "fd-find"
  # install_cargo_bin "rg" "ripgrep"
  # install_cargo_bin "z" "zoxide"
  install_cargo_bin "sd" "sd"
  install_cargo_bin "cargo-install-update" "cargo-update"
  # cargo install-update -a

  install_yazi() {
    if command -v yazi &>/dev/null; then
      echo "✅ yazi is already installed"
      return 0
    fi

    rm -rf ~/Downloads/yazi
    git clone https://github.com/sxyazi/yazi.git ~/Downloads/yazi
    cargo build --release --locked --manifest-path ~/Downloads/yazi/Cargo.toml

    sudo mv ~/Downloads/yazi/target/release/yazi /usr/local/bin/
    sudo mv ~/Downloads/yazi/target/release/ya /usr/local/bin/
  }
  install_yazi
} # }}}

install_nerd_font() { # {{{
  local -r font_name="JetBrainsMonoNLNerdFontMono"
  local -r version="v3.4.0"
  local -r download_url="https://github.com/ryanoasis/nerd-fonts/releases/download/${version}/JetBrainsMono.zip"
  local font_dir=""

  # Windows Font Directory = "/mnt/c/Windows/Fonts"
  case "$(uname)" in
  "Darwin") font_dir="${HOME}/Library/Fonts" ;;
  "Linux") font_dir="${HOME}/.local/share/fonts" ;;
  *)
    echo "⚠️ Unsupported OS"
    return 1
    ;;
  esac

  install_jetbrains_nerd_font() {
    if find "${font_dir}" -name "*${font_name}*" | grep -q "."; then
      echo "✅ ${font_name} is already installed. Skipping..."
      return 0
    fi

    echo "🔄 Installing ${font_name} ${version}..."

    # temp_dir="/tmp/fonts_setup"
    local -r temp_dir="${HOME}/Downloads/nerd_fonts_setup"
    mkdir -pv "${temp_dir}"

    echo "🔄 Downloading font archive..."
    curl -fLo "${temp_dir}/JetBrainsMono.zip" "${download_url}" --retry 3

    echo "🔄 Extracting files..."
    unzip -o "${temp_dir}/JetBrainsMono.zip" -d "${temp_dir}"

    mkdir -pv "${font_dir}"

    find "${temp_dir}" -name "JetBrainsMonoNLNerdFontMono-*.ttf" -exec cp {} "${font_dir}/" \;

    if [ "$(uname)" = "Linux" ]; then
      echo "🔄 Updating font cache..."
      fc-cache -f "${font_dir}"
    fi

    # rm -rf "${temp_dir}"
    echo "✅ Font installation completed successfully!"
  }
  install_jetbrains_nerd_font
} # }}}

update_snapd_packages() { # {{{
  if is_wsl; then
    return 0
  fi

  install_package snapd
  local -r stamp_file="/var/cache/snap-update-success-stamp"
  local last_update=0

  if [[ -f "${stamp_file}" ]]; then
    last_update=$(stat -c %Y "${stamp_file}" 2>/dev/null || echo 0)
  fi

  local now
  now=$(date +%s)
  local -r interval=$((86400 * 7))

  if ((now - last_update <= interval)); then
    echo "✅ Snap packages were updated recently. Skipping..."
    return 0
  fi

  echo "🔄 Updating snap packages..."

  if pgrep snap-store >/dev/null; then
    sudo killall -9 snap-store 2>/dev/null
  fi

  sudo snap install snap-store 2>/dev/null || true
  sudo snap refresh snap-store || true
  sudo snap refresh --list
  if sudo snap refresh; then
    sudo touch "${stamp_file}"
  else
    echo "⚠️ Snap refresh encountered an issue."
    return 1
  fi
} # }}}

upgrade_packages() { # {{{
  local -r stamp_file="/var/lib/apt/periodic/upgrade-stamp"
  local last_update=0

  if [[ -f "${stamp_file}" ]]; then
    last_update=$(stat -c %Y "${stamp_file}" 2>/dev/null || echo 0)
  fi

  local now
  now=$(date +%s)
  local -r interval=$((86400 * 7))

  if ((now - last_update <= interval)); then
    echo "✅ System packages were upgraded recently. Skipping..."
    return 0
  fi

  echo "🔄 Upgrading system packages..."

  if sudo DEBIAN_FRONTEND=noninteractive apt-get full-upgrade -y \
    -o Dpkg::Options::="--force-confdef" \
    -o Dpkg::Options::="--force-confold"; then

    sudo apt-get autoremove -y
    sudo apt-get autoclean -y

    sudo touch "${stamp_file}"
  else
    echo "⚠️ apt-get full-upgrade encountered an issue."
    return 1
  fi
} # }}}

setup_wayland_env() { # {{{
  if is_wsl; then
    return 0
  fi

  local env_vars=(
    "MOZ_ENABLE_WAYLAND=1"
    "QT_QPA_PLATFORM=wayland;xcb"
    "GDK_BACKEND=wayland,x11"
    "CLUTTER_BACKEND=wayland"
    "SDL_VIDEODRIVER=wayland,x11"
    "XDG_SESSION_TYPE=wayland"
    "_JAVA_AWT_WM_NONREPARENTING=1"
    "ELECTRON_OZONE_PLATFORM_HINT=auto"
    "WINIT_UNIX_BACKEND=wayland"
    "GBM_BACKEND=drm-kms"
  )

  if is_nvidia_hardware_present && is_nvidia_driver_ready; then
    env_vars=("${env_vars[@]/GBM_BACKEND=drm-kms/GBM_BACKEND=nvidia-drm}")
    env_vars+=(
      "LIBVA_DRIVER_NAME=nvidia"
      "__GLX_VENDOR_LIBRARY_NAME=nvidia"
      "NVD_BACKEND=direct"
    )
  fi

  local var
  for var in "${env_vars[@]}"; do
    local key="${var%%=*}"
    if ! grep -q "^${key}=" /etc/environment 2>/dev/null; then
      echo "${var}" | sudo tee -a /etc/environment >/dev/null
    else
      sudo sed -i "s|^${key}=.*|${var}|" /etc/environment
    fi
  done
} # }}}

setup_locale() { # {{{
  if command -v locale-gen &>/dev/null; then
    sudo locale-gen en_US.UTF-8
  else
    echo "⚠️ locale-gen not found. Skipping locale setup."
  fi
  sudo update-locale LANG=en_US.UTF-8
} # }}}

change_shell_to_zsh() { # {{{
  local -r zsh_path="$(command -v zsh)"
  if [ -n "${zsh_path}" ]; then
    local -r target_user="${SUDO_USER:-${USER}}"
    sudo chsh -s "${zsh_path}" "${target_user}"
  else
    echo "⚠️ Zsh is not installed or not in PATH."
  fi
} # }}}

cleanup() { # {{{
  if [[ -n "${SUDO_KEEP_ALIVE_PID:-}" ]] && kill -0 "${SUDO_KEEP_ALIVE_PID}" 2>/dev/null; then
    kill "${SUDO_KEEP_ALIVE_PID}" 2>/dev/null
  fi
} # }}}

main() { # {{{
  if is_ubuntu; then
    initialize_flags
    parse_args "${@}"

    local -a tasks=(
      show_script_info
      keep_sudo_alive
    )

    tasks+=(
      install_basic_packages
      make_default_directories
    )

    tasks+=(
      install_node
      install_global_packages
      install_rust
      install_nerd_font
    )

    if ((ENABLE_NVIDIA)); then
      tasks+=(setup_nvidia)
    fi

    if ((ENABLE_HANGUL_KEYMAP)); then
      tasks+=(make_RALT_to_HNGL)
    fi

    if ((ENABLE_SYSTEM_UPGRADE)); then
      tasks+=(
        update_snapd_packages
        upgrade_packages
      )
    fi

    if ((ENABLE_WAYLAND_ENV)); then
      tasks+=(setup_wayland_env)
    fi

    tasks+=(setup_locale)

    if ((ENABLE_CHANGE_SHELL)); then
      tasks+=(change_shell_to_zsh)
    fi
  else
    echo "❌ Error: Distro mismatch. Ubuntu only."
    exit 1
  fi

  local task
  for task in "${tasks[@]}"; do
    if declare -f "${task}" >/dev/null; then
      echo "============================================================"
      echo "${task}"
      echo "============================================================"
      "${task}"
      echo ""
      echo ""
      echo ""
    else
      echo "⚠️ Warning: Function '${task}' not found."
    fi
  done
} # }}}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  trap cleanup EXIT INT TERM ERR
  main "${@}"
fi
