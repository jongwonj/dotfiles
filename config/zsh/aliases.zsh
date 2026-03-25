# ~/.config/zsh/aliases.zsh
# ----------------------------------------------------------
if [[ "$(uname)" = "Linux" ]]; then
  alias cp='cp --force --archive --verbose'
  alias cpnp='cp --force --no-preserve=all --recursive --verbose'

  if [ -f /etc/os-release ] && grep -qi '^ID=ubuntu' /etc/os-release; then
    alias as="apt-cache search"

    alias bubo='sudo apt update && apt list --upgradable'
    alias bubc='sudo apt upgrade -y && sudo apt autoremove -y && sudo apt clean'
    alias bubu='bubo && bubc'
  fi

  if [[ "$(uname -a)" =~ "WSL" ]]; then
    alias f='explorer.exe'
  else
    alias f='xdg-open'
  fi

elif [ "$(uname)" = "Darwin" ]; then
  alias cp='cp -RXiv'
  alias f='open -a Finder'

  alias bubo='brew update && brew outdated'
  alias bubc='brew upgrade && brew cleanup'
  alias bubu='bubo && bubc'
fi

alias g='git'
alias gs='git status'
alias gd='git diff'
alias gds='git diff --stat'
alias gdc='git diff --cached'
alias gdcs='git diff --cached --stat'
alias gdv='nvim +DiffviewOpen'

alias ga='git add --verbose'
alias gaa='git add --verbose --all'
alias gc='git commit --verbose'
alias gcm='git commit --verbose --message'
alias gca='git commit --verbose --all'

alias gb='git branch --verbose'
alias gsw='git switch'
alias gswc='git switch -c'
alias gco='git checkout'
alias gcob='git checkout -b'

alias grs='git restore'
alias grss='git restore --staged'

alias gf='git fetch --verbose'
alias gl='git pull --verbose'
alias gp='git push --verbose'
alias gr='git remote --verbose'

alias gm='git merge --verbose'
alias grb='git rebase --verbose'
alias gcp='git cherry-pick'
alias gst='git stash'
alias gstp='git stash pop'

alias gg="git log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(bold yellow)%d%C(reset)' --all"
alias glp="git log --pretty=format:'%C(yellow)%h %C(magenta)%ad %C(cyan)%an %C(reset)%s' --date=short"
alias ggrep="git log --all --grep" # Search commit messages

alias dl='mkdir -p ~/Downloads && cd ~/Downloads'
alias dc='mkdir -p ~/Documents && cd ~/Documents'
alias p='mkdir -p ~/proj && cd ~/proj'

alias tmls='tmux ls'
alias tmat='tmux attach -t'
alias tmdt='tmux detach'
alias tmkl='tmux kill-session'

alias zshrc='test -f ~/.zshrc && vim ~/.zshrc || echo "File does not exist."'
alias alish='test -f ~/.config/zsh/aliases.zsh && vim ~/.config/zsh/aliases.zsh || echo "File does not exist."'
alias dotfiles='test -d ~/.dotfiles && cd ~/.dotfiles || echo "Directory does not exist."'
alias zsh='exec zsh'

alias c='clear'
alias h='history | tail -n 20'

alias mv='mv -iv'
alias mkdir='mkdir -pv'
alias ll='ls -AFhlp'
alias ls='ls -AF --color=auto'
alias mat2='mat2 --inplace --verbose'
alias d='date "+%Y-%m-%d (%a) %H:%M:%S %Z"'
alias numFiles='echo $(ls -1 | wc -l)'
alias v='vim'
alias vd='vimdiff'
alias vdc='cd ~/proj/personal/dotfiles/ && vimdiff ~/.dotfiles/config/nvim/init.lua config/nvim/init.lua'
alias vdz='cd ~/proj/personal/dotfiles/ && vimdiff ~/.zshrc home/.zshrc'
alias vda='cd ~/proj/personal/dotfiles/ && vimdiff ~/.dotfiles/config/zsh/aliases.zsh config/zsh/aliases.zsh'

if command -v yazi >/dev/null 2>&1; then
  alias yz='yazi'
fi

if command -v lazygit &>/dev/null; then
  alias lz='lazygit'
fi

if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh --cmd cd)"

  z() {
    __zoxide_z "$@" && ls -A
  }
  alias cd='z'
  alias z..='z ../'
else
  cd() {
    builtin cd "${@}"
    ls -A
  }
fi

mkcd() { mkdir -pv "${1}" && cd "${1}"; }
alias cd..='cd ../'
alias ..='cd ../'
alias ...='cd ../../'
alias .1='cd ../'
alias .2='cd ../../'
alias .3='cd ../../../'
alias .4='cd ../../../../'
alias .5='cd ../../../../../'
alias .6='cd ../../../../../../'

alias npmu='npm install -g'
alias bunu='bun add -g'
alias deu='deno install --allow-all --force'
alias cgu='cargo install'
alias pxu='pipx upgrade'
alias pxu_all='pipx upgrade-all'
alias uvs='uv self update'
alias uvu='uv tool install --upgrade'

npmu_all() {
  if command -v jq >/dev/null 2>&1; then
    local pkgs
    pkgs=$(npm list -g --depth=0 --json 2>/dev/null | jq -r '.dependencies // {} | keys[]' 2>/dev/null | grep -v "^npm$")
    if [[ -n "${pkgs}" ]]; then
      echo "${pkgs}" | xargs npm install -g
    fi
  else
    local raw_pkgs
    raw_pkgs=$(npm list -g --depth=0 2>/dev/null | awk '/@/ {print $NF}' | sed 's/@[^@]*$//' | grep -v "^npm$")
    if [[ -n "${raw_pkgs}" ]]; then
      echo "${raw_pkgs}" | xargs npm install -g
    fi
  fi
}

bunu_all() {
  bun upgrade
}

deu_all() {
  deno upgrade
}

cgu_all() {
  if command -v cargo-install-update >/dev/null 2>&1; then
    cargo install-update -a
  else
    echo "'cargo-update' is not installed. Run: cargo install cargo-update"
  fi
}

uvu_all() {
  uv tool upgrade --all 2>/dev/null || {
    local tools
    tools=$(uv tool list | awk '{print $1}')
    if [[ -n "${tools}" ]]; then
      echo "${tools}" | xargs -I {} uv tool install {} --upgrade
    else
      echo "No uv tools installed."
    fi
  }
}

upgrade_all_managers() {
  command -v npm >/dev/null 2>&1 && npmu_all
  command -v pipx >/dev/null 2>&1 && pipx upgrade-all
  command -v cargo >/dev/null 2>&1 && cgu_all
  command -v uv >/dev/null 2>&1 && uvu_all

  # 🚀 Executing Runtime Self-Upgrades.
  command -v bun >/dev/null 2>&1 && bunu_all
  command -v deno >/dev/null 2>&1 && deu_all
  command -v uv >/dev/null 2>&1 && uv self update
}
if typeset -f upgrade_all_managers >/dev/null; then
  alias upall='upgrade_all_managers'
fi

if command -v clang >/dev/null 2>&1; then
  export CC="clang"
  export CXX="clang++"
fi

typeset -g common_excludes=(.git node_modules dist build .next .cache .turbo .vite coverage target __pycache__ .venv)

if command -v eza >/dev/null; then
  readonly ezaExclude="${(j:|:)common_excludes}"
  xmfl() { command eza --tree --all --ignore-glob="${ezaExclude}" "${@}"; }
  xmfl1() { command eza --tree --level 1 --all --ignore-glob="${ezaExclude}" "${@}"; }
  xmfl2() { command eza --tree --level 2 --all --ignore-glob="${ezaExclude}" "${@}"; }
  xmfl3() { command eza --tree --level 3 --all --ignore-glob="${ezaExclude}" "${@}"; }
  xmflsrc() { command eza --tree src --all --ignore-glob="${ezaExclude}" "${@}"; }
  xmfld() { command eza --tree --only-dirs --all --ignore-glob="${ezaExclude}" "${@}"; }
  xmfll() {
    local level="${1:-2}"
    command eza --tree --level "${level}" --all --ignore-glob="${ezaExclude}" "${@:2}"
  }
fi

if command -v tree >/dev/null; then
  readonly treeExclude="${(j:|:)common_excludes}"
  tree() { command tree -a -I "${treeExclude}" "${@}"; }
  tree1() { command tree -L 1 -a -I "${treeExclude}" "${@}"; }
  tree2() { command tree -L 2 -a -I "${treeExclude}" "${@}"; }
  tree3() { command tree -L 3 -a -I "${treeExclude}" "${@}"; }
  treesrc() { command tree src -a -I "${treeExclude}" "${@}"; }
  treed() { command tree -d -a -I "${treeExclude}" "${@}"; }
  treel() {
    local level="${1:-2}"
    command tree -L "${level}" -a -I "${treeExclude}" "${@:2}"
  }
fi

if command -v fd >/dev/null 2>&1; then
  _FD_CMD="fd"
elif command -v fdfind >/dev/null 2>&1; then
  _FD_CMD="fdfind"
else
  _FD_CMD=""
fi

if [ -n "${_FD_CMD}" ]; then
  fd_exclude_args=()
  for d in ${common_excludes}; do fd_exclude_args+=("-E" "${d}"); done

  ff() { ${_FD_CMD} -i --hidden "${fd_exclude_args[@]}" "${@}"; }
  ffs() { ${_FD_CMD} -i --hidden "${fd_exclude_args[@]}" "^${@}"; }
  ffe() { ${_FD_CMD} -i --hidden "${fd_exclude_args[@]}" "${@}$"; }

  alias fdf="${_FD_CMD} -i --hidden -t f ${fd_exclude_args[*]}"
  alias fdf-ext="${_FD_CMD} -i --hidden -t f ${fd_exclude_args[*]} -e"
  alias fdf-s="${_FD_CMD} -s --hidden -t f ${fd_exclude_args[*]}"
  alias fdd="${_FD_CMD} -i --hidden -t d ${fd_exclude_args[*]}"
  alias fdd-s="${_FD_CMD} -s --hidden -t d ${fd_exclude_args[*]}"
else
  find_exclude_args=()
  for d in ${common_excludes}; do find_exclude_args+=("-not" "-path" "*/${d}/*"); done

  ff() { find . -iname "*${@}*" "${find_exclude_args[@]}"; }
  ffs() { find . -iname "${@}*" "${find_exclude_args[@]}"; }
  ffe() { find . -iname "*${@}" "${find_exclude_args[@]}"; }

  function fdf { find . -type f -iname "*${1}*" "${find_exclude_args[@]}"; }
  alias fdf-ext='echo "❌ fd not installed. Use: find . -name \"*.ext\""'
  function fdd { find . -type d -iname "*${1}*" "${find_exclude_args[@]}"; }
fi

if command -v rg >/dev/null 2>&1; then
  rg_exclude_args=()
  for d in ${common_excludes}; do rg_exclude_args+=("-g" "!${d}/*"); done

  rgp() { rg --column --line-number --no-heading --smart-case --hidden --follow "${rg_exclude_args[@]}" --color 'always' --fixed-strings "${@}"; }
  rgr() { rg --column --line-number --no-heading --smart-case --hidden --follow "${rg_exclude_args[@]}" --color 'always' --regexp "${@}"; }
else
  grep_exclude_args=()
  for d in ${common_excludes}; do grep_exclude_args+=("--exclude-dir=${d}"); done

  rgp() { grep --recursive --line-number --color=always --ignore-case "${grep_exclude_args[@]}" --fixed-strings "${@}"; }
  rgr() { grep --recursive --line-number --color=always --ignore-case "${grep_exclude_args[@]}" --extended-regexp "${@}"; }
fi

if command -v eza >/dev/null 2>&1; then
  _EZA_CMD="eza"
else
  _EZA_CMD=""
fi

if [ -n "${_EZA_CMD}" ]; then
  alias ls="${_EZA_CMD} -F --group-directories-first --color=auto"
  alias lsa="${_EZA_CMD} -abghilmuF --group-directories-first --git --time-style=long-iso --icons --header"
  alias lt="${_EZA_CMD} -T --icons"
  alias ll="ls -hal --git"
else
  if [[ "${OSTYPE}" == "darwin"* ]]; then
    alias ls='ls -AFG'
    alias ll='ls -AFGhlp'
    alias lsa='ls -alFG'
  else
    alias ls='ls -AF --color=auto'
    alias ll='ls -AFhlp --color=auto'
    alias lsa='ls -al --color=auto'
  fi
fi

fde() {
  local target="${1:-.}"
  ${_FD_CMD} . "${target}" -X ${_EZA_CMD} -ld --icons --git
}

if command -v batcat >/dev/null; then
  alias bat="batcat"
fi

histrm() {
  clear
  [ -f ~/.bash_history ] && rm -f ~/.bash_history
  [ -f ~/.zsh_history ] && rm -f ~/.zsh_history
  [ -d ~/.zsh_cache ] && rm -rf ~/.zsh_cache
  exec ${SHELL}
}

zipf() {
  for file in "${@}"; do
    zip -r "${file}".zip "${file}"
  done
}

djszip() {
  for file in "${@}"; do
    unzip -O cp949 "${file}" -d "${file%%.zip}"
  done
}

if command -v 7zz &>/dev/null; then
  sevenZipCommand="7zz"

elif command -v 7z &>/dev/null; then
  sevenZipCommand="7z"
else
  sevenZipCommand=""
fi

if [ -n "${sevenZipCommand}" ]; then
  djs7z() {
    printf "%s" "Password: "
    read -s PASSWORD
    echo

    for file in "${@}"; do
      ${sevenZipCommand} x "${file}" -p"${PASSWORD}"
    done
  }

  clfz() {
    for file in "${@}"; do
      ${sevenZipCommand} a -t7z -m0=lzma2 -mx=0 -mfb=64 -md=32m -ms=on "${file}".7z "${file}"
    done
  }

  clfzp() {
    printf "%s" "Password: "
    read -s PASSWORD
    echo

    for file in "${@}"; do
      ${sevenZipCommand} a -t7z -m0=lzma2 -mx=0 -mfb=64 -md=32m -ms=on -mhe=on -p"${PASSWORD}" "${file}".7z "${file}"
    done
  }

  clfzcp() {
    for file in "${@}"; do
      ${sevenZipCommand} a -t7z -m0=copy "${file}".7z "${file}"
    done
  }

  clfzpcp() {
    printf "%s" "Password: "
    read -s PASSWORD
    echo

    for file in "${@}"; do
      ${sevenZipCommand} a -t7z -m0=copy -mhe=on -p"${PASSWORD}" "${file}".7z "${file}"
    done
  }
fi

vimrc() {
  local editor="${VISUAL:-${EDITOR:-vim}}"

  local config_paths=(
    "${HOME}/.config/nvim/init.lua"
    "${HOME}/.config/nvim/init.vim"
    "${HOME}/.config/vim/vimrc"
    "${HOME}/.vimrc"
    "${HOME}/.vim/vimrc"
  )

  local target_path
  for target_path in "${config_paths[@]}"; do
    if [[ -f "${target_path}" ]]; then
      "${editor}" "${target_path}"
      return 0
    fi
  done

  echo "Error: No Vim/Neovim configuration file found." >&2
  return 1
}
alias vc='vimrc'

dirdiff() {
  if [ -z "${1}" ] || [ -z "${2}" ]; then
    echo "Usage: dirdiff <directory1> <directory2> [diff_options]"
    return 1
  fi
  DIR1="${1}"
  shift
  DIR2="${1}"
  shift
  diff --brief --recursive "${DIR1}" "${DIR2}" "${@}"
}

updatectags() {
  local watch_mode=false
  local exts=()

  while [[ ${#} -gt 0 ]]; do
    case "${1}" in
    -w | --watch)
      watch_mode=true
      shift
      ;;
    *)
      exts+=("${1}")
      shift
      ;;
    esac
  done

  local exclude_pattern="${(j:|:)common_excludes//./\\.}"
  exclude_pattern="${exclude_pattern}|tags"

  local ext_filter="."
  if [ ${#exts[@]} -gt 0 ]; then
    ext_filter="\.($(echo ${(j:|:)exts}))$"
  fi

  get_files() {
    find . -type f 2>/dev/null | grep -vE "(${exclude_pattern})" | grep -E "${ext_filter}"
  }

  run_ctags() {
    local files=($(get_files))
    if [ ${#files[@]} -eq 0 ]; then
      echo "⚠️  No files found to index."
      return 1
    fi

    if ctags --version 2>&1 | grep -iq "universal"; then
      printf "%s\n" "${files[@]}" | ctags --append=no --fields=+iaS --extras=+q -L -
    else
      printf "%s\n" "${files[@]}" | ctags -L -
    fi
    echo "✅ Tags updated. (${#files[@]} files indexed)"
  }

  run_ctags

  if [ "${watch_mode}" = true ]; then
    if ! command -v entr >/dev/null 2>&1; then
      echo "❌ 'entr' is not installed."
      return 1
    fi

    echo "👀 Watching for changes... (Ctrl+C to stop)"

    trap "trap - INT; echo '\n🛑 Stopped.'; return" INT

    while true; do
      get_files | entr -d -p zsh -c "source ~/.config/zsh/aliases.zsh && updatectags"

      if [ ${?} -gt 128 ]; then break; fi

      sleep 0.5
    done
    trap - INT
  fi
}

sshload() {
  if [ -n "${SSH_AGENT_PID}" ] && kill -0 "${SSH_AGENT_PID}" 2>/dev/null; then
    echo "Reusing existing SSH agent (PID: ${SSH_AGENT_PID})."
  else
    unset SSH_AUTH_SOCK SSH_AGENT_PID
    eval $(ssh-agent -s)
    echo "Started new SSH agent (PID: ${SSH_AGENT_PID})."
  fi

  local exclude_names=(! \( -name "*.pub" -o -name "*.bak" -o -name "*~" -o -name "id_*_" \))
  local include_names=(\( -name "id_rsa" -o -name "id_ecdsa" -o -name "id_ed25519" -o -name "id_ed25519_*" \))

  local keys=("${@}")

  if [ "${#keys[@]}" -eq 0 ]; then
    # keys=($(find ~/.ssh -type f -name "id_*" ! -name "*.pub"))
    keys=(${(f)"$(find ~/.ssh -type f "${exclude_names[@]}" "${include_names[@]}" | sort)"})

    if [ "${#keys[@]}" -eq 0 ]; then
      echo "No SSH keys found in ~/.ssh directory."
      return 1
    fi
  fi

  local success_count=0
  local failure_count=0

  for key in "${keys[@]}"; do
    if [ -f "${key}" ]; then
      if ssh-add "${key}"; then
        echo "Key '${key}' added successfully."
        ((success_count++))
      else
        echo "Failed to add key '${key}'. Check passphrase or permissions."
        ((failure_count++))
      fi
    else
      echo "Key file '${key}' does not exist."
      ((failure_count++))
    fi
  done

  echo ""
  echo "Currently loaded SSH keys:"
  ssh-add -l
  echo ""
  echo "Summary: ${success_count} keys added successfully, ${failure_count} failures."
}

sshkill() {
  local agent_pids
  agent_pids=(${(f)"$(pgrep ssh-agent)"})

  if [ -z "${agent_pids}" ]; then
    echo "No SSH agents are currently running."
    return 0
  fi

  echo "Stopping all SSH agents..."
  for pid in "${agent_pids[@]}"; do
    kill "${pid}" && echo "Stopped agent PID: ${pid}."
  done

  unset SSH_AUTH_SOCK SSH_AGENT_PID
}

if command -v fzf &>/dev/null; then
  local _preview_cmd=""
  if command -v bat &>/dev/null; then
    _preview_cmd="bat"
  elif command -v batcat &>/dev/null; then
    _preview_cmd="batcat"
  else
    _preview_cmd="cat"
  fi

  export FZF_DEFAULT_OPTS="--height 95% --layout=reverse --border --inline-info \
    --preview '${_preview_cmd} --style=numbers --color=always --line-range :500 {}' \
    --preview-window 'right:65%,border-left,follow,cycle,sharp' \
    --bind 'ctrl-/:toggle-preview' \
    --bind 'alt-j:down,alt-k:up' \
    --color='header:italic,info:244,pointer:208,marker:208,fg+:252,bg+:235,hl+:210'"

  if [ -n "${_FD_CMD}" ]; then
    export FZF_DEFAULT_COMMAND="${_FD_CMD} --type f --hidden --follow --exclude .git"
    export FZF_CTRL_T_COMMAND="${FZF_DEFAULT_COMMAND}"
    local _FD_DIR_CMD="${_FD_CMD} --type d --hidden --follow --exclude .git"
  else
    local _FD_DIR_CMD="find . -path '*/.*' -prune -o -type d -print"
  fi

  if [[ "$(uname)" == "Darwin" ]]; then
    source <(fzf --zsh)
  else
    if [ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]; then
      source /usr/share/doc/fzf/examples/key-bindings.zsh
      source /usr/share/doc/fzf/examples/completion.zsh
    elif [ -f ~/.fzf.zsh ]; then
      source ~/.fzf.zsh
    fi
  fi

  fe() {
    local file=$(fzf --query="${1}" --select-1 --exit-0)
    [ -n "${file}" ] && ${EDITOR:-vim} "${file}"
  }

  fcd() {
    local dir
    dir=$(eval "${_FD_DIR_CMD}" | fzf --preview 'tree -C {} | head -100' --preview-window 'right:50%')
    [ -n "${dir}" ] && cd "${dir}"
  }

  fgb() {
    local branch=$(git branch --all | grep -v 'HEAD' | fzf --header "[Git Branches]" --preview-window 'hidden')
    [ -n "${branch}" ] && git checkout $(echo "${branch}" | sed "s/.* //" | sed "s#remotes/[^/]*/##")
  }

  fkill() {
    local pid=$(ps -u ${USER} -o pid,stat,comm | fzf --header '[Kill Process]' --height 50% --preview-window 'hidden' | awk '{print $1}')
    [ -n "${pid}" ] && echo "${pid}" | xargs kill -9
  }

  fhist() {
    print -z $(history | fzf --height 95% --layout=reverse --tiebreak=index | sed 's/^[ ]*[0-9]*[ ]*//')
  }
fi
