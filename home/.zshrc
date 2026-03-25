# ~/.zshrc
# ----------------------------------------------------------
export LANG="en_US.UTF-8"
export LANGUAGE="en_US:en"
export LC_ALL="en_US.UTF-8"
setopt NO_BEEP
bindkey -v

if [[ "$(uname)" = "Linux" ]]; then
  zshAutoDir=~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
  zshHighDir=~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
  [ -f ${zshAutoDir} ] && source ${zshAutoDir}
  fpath=(~/.zsh/zsh-completions/src ${fpath})
  export PATH="$PATH:/opt/nvim-linux-x86_64/bin"

  if [[ "$(uname -a)" =~ "WSL" ]]; then
    export LS_COLORS=$LS_COLORS:'ow=01;34:tw=01;34:'
  fi

  autoload -Uz compinit
  if [ -f ~/.zcompdump ] && [ $(date +'%j') != $(date -r ~/.zcompdump +'%j') ]; then
    compinit
  else
    compinit -C
  fi

  [ -f ${zshHighDir} ] && source ${zshHighDir}
  fpath=(${HOME}/.local/bin ${fpath})
  ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=244,bold'
  export PATH=${PATH}:/usr/local/go/bin

elif [ "$(uname)" = "Darwin" ];then
  if type brew &>/dev/null; then
    zshAutoDir="$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
    zshHighDir="$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
    [ -f ${zshAutoDir} ] && source ${zshAutoDir}
    [ -f ${zshHighDir} ] && source ${zshHighDir}
    FPATH=$(brew --prefix)/share/zsh-completions:${FPATH}
    autoload -Uz compinit
    compinit
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=244,bold'
  fi

  export PATH="/opt/homebrew/bin":${PATH}
  export PATH="/usr/local/bin":${PATH}

  export CLICOLOR=1
  export LSCOLORS="gxfxcxdxbxegedabagacad"
fi

if (( $+commands[nvim] )); then
  export VISUAL="nvim"
else
  export VISUAL="vim"
fi
export EDITOR="${VISUAL}"
export GIT_EDITOR="${VISUAL}"
export FCEDIT="${VISUAL}"
alias vi="${VISUAL}"
alias vim="${VISUAL}"
alias vimdiff="${VISUAL} -d"

if [ -d "${HOME}/.config/zsh" ]; then
  if [ -n "${BASH_VERSION}" ]; then
    shopt -s nullglob
  elif [ -n "${ZSH_VERSION}" ]; then
    setopt local_options nullglob
  fi

  for config_file in "${HOME}/.config/zsh"/*.zsh; do
    if [ -f "${config_file}" ]; then
      source "${config_file}"
    fi
  done

  if [ -n "$BASH_VERSION" ]; then
    shopt -u nullglob
  fi
fi

if [ -f "${HOME}/.zshrc.secret" ]; then
  source "${HOME}/.zshrc.secret"
fi

if ! (( $+commands[starship] )); then
  zstyle -d ':completion:*' list-colors
fi

_tmux_auto_attach() {
  local session_name="${1}"
  if (( $+commands[tmux] )) && \
    [ -n "${PS1}" ] && [ -z "${TMUX}" ] && \
    [[ ! "${TERM}" =~ screen ]] && [[ ! "${TERM}" =~ tmux ]] && \
    [[ ! "${TERM_PROGRAM}" =~ vscode ]]; then
  tmux -L main -f ~/.config/tmux/tmux.conf new-session -AD -s "${session_name}"
  fi
}
ajrtm()  { _tmux_auto_attach "main"; }
ajr1() { _tmux_auto_attach "main1"; }
ajr2() { _tmux_auto_attach "main2"; }
ajr3() { _tmux_auto_attach "main3"; }
ajr4() { _tmux_auto_attach "main4"; }
ajr5() { _tmux_auto_attach "main5"; }

if [[ "${TERM_PROGRAM}" != "Apple_Terminal" ]] && \
  [[ "${TERM}" != "screen" ]] && \
  [[ "${TERM}" != "tmux" ]] && \
  [[ "${TERM}" != "linux" ]]; then
  export COLORTERM="truecolor"
fi

export XDG_CONFIG_HOME="${HOME}/.config"
export XDG_DATA_HOME="${HOME}/.local/share"
export XDG_STATE_HOME="${HOME}/.local/state"
export XDG_CACHE_HOME="${HOME}/.cache"

export HISTFILE="${HOME}/.zsh_history"
export HISTSIZE=1000
export SAVEHIST=${HISTSIZE}

export PATH="${HOME}/.local/bin":${PATH}
export UNZIP="-O cp949"
export ZIPINFO="-O cp949"

setopt INC_APPEND_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_SAVE_NO_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_REDUCE_BLANKS

if ! (( $+commands[starship] )); then
  autoload -Uz vcs_info
  precmd_vcs_info() { vcs_info }
  precmd_functions+=( precmd_vcs_info )
  setopt prompt_subst
  zstyle ':vcs_info:git:*' enable git
  zstyle ':vcs_info:git:*' check-for-changes true
  zstyle ':vcs_info:git:*' stagedstr ' +'
  zstyle ':vcs_info:git:*' unstagedstr ' *'
  zstyle ':vcs_info:git:*' untrackedstr ' ?'
  zstyle ':vcs_info:git:*' formats ' (%b%m%u%c)'
  zstyle ':vcs_info:git:*' actionformats ' (%b|%a)'

  autoload -U colors && colors
  local prompt_string=""
  if [[ -n "${SSH_CONNECTION}" ]]; then
    prompt_string+='%F{yellow}%n@%m%f '
  fi
  prompt_string+='%(?..%F{red}[%?]%f )'
  prompt_string+='%F{blue}%B%5~%b%f'
  prompt_string+='${vcs_info_msg_0_}'
  prompt_string+='%# '
  PROMPT="${prompt_string}"
fi

[ -f "${HOME}/.cargo/env" ] && . "${HOME}/.cargo/env"

# node
export NVM_DIR="${HOME}/.nvm"
[ -s "${NVM_DIR}/nvm.sh" ] && \. "${NVM_DIR}/nvm.sh"
[ -s "${NVM_DIR}/bash_completion" ] && \. "${NVM_DIR}/bash_completion"

# deno
[ -f "${HOME}/.deno/env" ] && . "${HOME}/.deno/env"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
[ -s "$BUN_INSTALL/_bun" ] && source "$BUN_INSTALL/_bun"

if (( $+commands[starship] )); then
  eval "$(starship init zsh)"
fi

local_env_file="${HOME}/.local/bin/env"
[ -f "${local_env_file}" ] && . "${local_env_file}"
