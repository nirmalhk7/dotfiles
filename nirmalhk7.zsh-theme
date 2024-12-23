# vim:ft=zsh ts=2 sw=2 sts=2
#
# nirmalhk7's Theme - https://gist.github.com/3712874
# A Powerline-inspired theme for ZSH
#
# # README
#
# In order for this theme to render correctly, you will need a
# [Powerline-patched font](https://gist.github.com/1595572).
#
# In addition, I recommend the
# [Solarized theme](https://github.com/altercation/solarized/) and, if you're
# using it on Mac OS X, [iTerm 2](http://www.iterm2.com/) over Terminal.app -
# it has significantly better color fidelity.
#
# # Goals
#
# The aim of this theme is to only show you *relevant* information. Like most
# prompts, it will only show git information when in a git working directory.
# However, it goes a step further: everything from the current user and
# hostname to whether the last call exited with an error to whether background
# jobs are running in this shell will all be displayed automatically when
# appropriate.

### Segments of the prompt, default order declaration

typeset -aHg nirmalhk7_left_prompts=(
    __prompt_context
    __prompt_dir
    __prompt_end
)

typeset -aHg nirmalhk7_right_segment=(
    __prompt_nodejs
    __prompt_python
    __prompt_git
)

### Segment drawing
# A few utility functions to make it easy and re-usable to draw segmented prompts

CURRENT_BG='NONE'
if [[ -z "$PRIMARY_FG" ]]; then
	PRIMARY_FG=black
fi

# Characters
SEGMENT_SEPARATOR=""
PLUSMINUS="\u00b1"
BRANCH="\ue0a0"
DETACHED="\u27a6"
CROSS="\u2718"
LIGHTNING="\u26a1"
GEAR="\u2699"

# Begin a segment
# Takes two arguments, background and foreground. Both can be omitted,
# rendering default background/foreground.
__prompt_segment() {
  local bg fg
  [[ -n $1 ]] && bg="%K{$1}" || bg="%k"
  [[ -n $2 ]] && fg="%F{$2}" || fg="%f"
  if [[ $CURRENT_BG != 'NONE' && $1 != $CURRENT_BG ]]; then
    print -n "%{$bg%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR%{$fg%}"
  else
    print -n "%{$bg%}%{$fg%}"
  fi
  CURRENT_BG=$1
  [[ -n $3 ]] && print -n " $3 "
}

# End the prompt, closing any open segments
__prompt_end() {
    if [[ -n $CURRENT_BG ]]; then
        echo -n "%{%k%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR"
    else
        echo -n "%{%k%}"
    fi
    echo -n "%{%f%}"
    CURRENT_BG=''
}

### Prompt components
# Each component will draw itself, and hide itself if no information needs to be shown

# Context: user@hostname (who am I and where am I)
__prompt_context() {
    if [[ "$USERNAME" != "$DEFAULT_USER" || -n "$SSH_CLIENT" ]]; then
        currenttime=$(date +%H:%M)
        if [ $RETVAL -ne 0 ];then
              __prompt_segment default red "%B%n@%m%b"
            elif [[ "$currenttime" > "23:00" ]] || [[ "$currenttime" < "07:00" ]]; then
              __prompt_segment default white "%B%n@%m%b"
        else
            __prompt_segment default green "%B%n@EXCALIBUR"
        fi
    fi
}


__prompt_project() {
  local color ref
  is_dirty() {
    test -n "$(git status --porcelain --ignore-submodules)"
  }
  return "$vcs_info_msg_0_"
}

# Git: branch/detached head, dirty status
__prompt_git() {
  local color ref
  is_dirty() {
    test -n "$(git status --porcelain --ignore-submodules)"
  }
  ref="$vcs_info_msg_0_"
  if [[ -n "$ref" ]]; then
    if is_dirty; then
      color=yellow
      ref="${ref} $PLUSMINUS"
    else
      color=green
      ref="${ref}"
    fi
    if [[ "${ref/.../}" == "$ref" ]]; then
      ref="$BRANCH $ref"
    else
      ref="$DETACHED ${ref/.../}"
    fi
    __prompt_segment $color $PRIMARY_FG
    print -n " $ref "
  fi
}

# Dir: current working directory
__prompt_dir() {
  local dir="${${(%):-%~}}"
  local parts=("${(s:/:)dir}")
  if (( ${#parts[@]} > 4 )); then
    dir=".../${parts[-3]}/${parts[-2]}/${parts[-1]}"
  else
    dir="${dir}"
  fi
  __prompt_segment blue white "%B$dir%b"
}

__prompt_python() {
    #   $VIRTUAL_ENV_DISABLE_PROMPT=1
    if [[ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" = "true" ]] then
        if [[ -n "$(find . -maxdepth 2 -type f -regextype posix-extended -regex '.*.(py|ipynb)' 2>/dev/null)" ]]; then
           local envlist=()
            if [[ -n "$CONDA_DEFAULT_ENV" ]]; then
                envlist+=($CONDA_DEFAULT_ENV)
            fi
            if [[ -n "$VIRTUAL_ENV" && -n "$VIRTUAL_ENV_DISABLE_PROMPT" ]]; then
                envlist+=(${VIRTUAL_ENV:t:gs/%/%%})
            fi
            ____prompt_segment cyan white "$envlist"
        fi
    fi
}

__prompt_nodejs(){
  local color ref
  is_dirty() {
    test -n "$(git status --porcelain --ignore-submodules)"
  }
  ref="$vcs_info_msg_0_"


  if [[ -n "$ref" ]]; then
    if [[ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" = "true" ]] then
        local filepath="$(git rev-parse --show-toplevel)"
        if [[ -e "$filepath/package.json" ]] then
            local version="$(node -p -e "require('$filepath/package.json').version")"
            __prompt_segment white black $version
        fi
    fi
  fi
}

## Main prompt
__prompt_nirmalhk7_left() {
  RETVAL=$?
  CURRENT_BG='NONE'
  for __prompt_segment in "${nirmalhk7_left_prompts[@]}"; do
    [[ -n $__prompt_segment ]] && $__prompt_segment
  done
}

__prompt_nirmalhk7_right() {
  RETVAL=$?
  CURRENT_BG='NONE'
  for __prompt_segment in "${nirmalhk7_right_segment[@]}"; do
    [[ -n $__prompt_segment ]] && $__prompt_segment
  done
}

prompt_nirmalhk7_precmd() {
  vcs_info
  PROMPT='%{%f%b%k%}$(__prompt_nirmalhk7_left) '
  RPROMPT='%{%f%b%k%}$(__prompt_nirmalhk7_right)'
}

prompt_nirmalhk7_setup() {
  autoload -Uz add-zsh-hook
  autoload -Uz vcs_info

  prompt_opts=(cr subst percent)

  add-zsh-hook precmd prompt_nirmalhk7_precmd

  zstyle ':vcs_info:*' enable git
  zstyle ':vcs_info:*' check-for-changes false
  zstyle ':vcs_info:git*' formats '%b'
  zstyle ':vcs_info:git*' actionformats '%b (%a)'
}

prompt_nirmalhk7_setup "$@"