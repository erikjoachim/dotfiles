# ===========================
# Bash Aliases
# ===========================
alias clr="clear"
alias rb="source ~/.bashrc && echo reloaded bashrc.."

# ===========================
# Nav Aliases
# ===========================
alias cd.="cd .."
alias cd..="cd .. && cd .."
alias ..="cd .."
alias cdinit="cd /c/projects/"
alias exp="explorer ."

# Colors
BLUE="\033[1;34m"
GREEN="\033[1;32m"
RESET="\033[0m"

# 'ls' tree view
lt() {
    for f in *; do
        if [ -d "$f" ]; then
            printf "${BLUE}%s/${RESET}\n" "$f"
        else
            printf "${GREEN}%s${RESET}\n" "$f"
        fi
    done
}

# 'ls -a' tree view
lta() {
    for f in .* *; do
        [ "$f" = "." ] || [ "$f" = ".." ] && continue
        if [ -d "$f" ]; then
            printf "${BLUE}%s/${RESET}\n" "$f"
        else
            printf "${GREEN}%s${RESET}\n" "$f"
        fi
    done
}

# ===========================
# Git Aliases & functions
# ===========================
alias gl="git log --pretty=format:'%C(yellow)[%ad]%C(reset) %C(green)[%h]%C(reset) | %C(red)%s %C(bold red){{%an}}%C(reset) %C(blue)%d%C(reset)' --graph --date=short"
alias gl2="git log --graph --pretty=format:'%C(auto)%h %s%C(reset)' --abbrev-commit"
alias gl-premium="git log --graph --abbrev-commit --decorate --pretty=format:'%C(auto)%h%C(reset) %C(bold)%s%C(reset)%C(dim white) · %an%C(reset)%C(yellow)%d%C(reset)'"
alias gl-dates="git log --graph --abbrev-commit --decorate --date=short --pretty=format:'%C(auto)%h%C(reset) %C(white)%s%C(reset) %C(dim white)%ad%C(reset)%C(yellow)%d%C(reset)'"
alias gs="git status"
alias gd="git diff"
alias gp="git pull"
alias gc="git checkout"
alias ga="git add"
alias gaa="git add . && git status"
alias gr="git restore"
alias gcm="git commit -m"
alias gci="git commit"
alias gb="git branch"

git_branch() {
     git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}

# ===========================
# Tools aliases
# ===========================
alias oc="opencode"

# ===========================
# SSH agent: portable Git Bash / Linux / macOS
# Probes agent liveness; stale SSH_AUTH_SOCK never reused.
# Profiles: ssa (personal) | ssa personal | ssa work | ssa all | ssa /path/to/key
# ===========================
alias ssa="start_ssh_agent"

# Per-machine overrides (export before reload, or set in parent env):
#   SSA_PERSONAL_KEYS="$HOME/.ssh/my-personal-key"
#   SSA_WORK_KEYS="$HOME/.ssh/my-work-key"
: "${SSA_PERSONAL_KEYS:=$HOME/.ssh/githubssh $HOME/.ssh/id_ed25519_personal $HOME/.ssh/id_ed25519}"
: "${SSA_WORK_KEYS:=$HOME/.ssh/github-work $HOME/.ssh/id_ed25519_work $HOME/.ssh/azure-devops-work $HOME/.ssh/id_ed25519_azure_work}"
: "${SSA_AGENT_ENV:=$HOME/.ssh/agent.env}"

_ssa_ensure_agent() {
    # Reuse env saved by previous shell
    if [ -f "$SSA_AGENT_ENV" ]; then
        # shellcheck disable=SC1090
        . "$SSA_AGENT_ENV" >/dev/null 2>&1
    fi

    # Probe liveness: 0 = keys loaded, 1 = alive but empty, 2 = no agent
    if ssh-add -l >/dev/null 2>&1; then
        return 0
    elif [ $? -eq 1 ]; then
        return 0
    fi

    # Dead/stale agent (reboot, /tmp wipe, lingering GUI env). Purge.
    local old_sock="${SSH_AUTH_SOCK:-}"
    if [ -n "${SSH_AGENT_PID:-}" ]; then
        kill "$SSH_AGENT_PID" >/dev/null 2>&1
    fi
    unset SSH_AUTH_SOCK SSH_AGENT_PID
    case "$old_sock" in
        /tmp/ssh-*/agent.*) rm -f "$old_sock" 2>/dev/null ;;
    esac

    eval "$(ssh-agent -s)" || { echo "ssa: failed to start ssh-agent" >&2; return 1; }
    printf 'SSH_AUTH_SOCK=%s\nexport SSH_AUTH_SOCK\nSSH_AGENT_PID=%s\nexport SSH_AGENT_PID\n' \
        "$SSH_AUTH_SOCK" "$SSH_AGENT_PID" > "$SSA_AGENT_ENV"
    chmod 600 "$SSA_AGENT_ENV"
}

_ssa_add_key() {
    local key="$1" label="${2:-$1}" fp=""
    if [ ! -f "$key" ]; then
        echo "ssa: skip $label (missing $key)" >&2
        return 1
    fi
    fp="$(ssh-keygen -lf "$key" 2>/dev/null | awk '{print $2}')"
    if [ -z "$fp" ]; then
        echo "ssa: skip $label (unreadable $key)" >&2
        return 1
    fi
    if ssh-add -l 2>/dev/null | grep -q "$fp"; then
        echo "ssa: $label already added."
        return 0
    fi
    if ssh-add "$key"; then
        echo "ssa: $label added."
        return 0
    else
        echo "ssa: failed to add $label" >&2
        return 1
    fi
}

start_ssh_agent() {
    local profile="${1:-personal}" key="" added=0 failed=0
    _ssa_ensure_agent || return 1
    case "$profile" in
        personal)
            for key in $SSA_PERSONAL_KEYS; do
                if _ssa_add_key "$key" "personal ($(basename "$key"))"; then
                    added=$((added + 1))
                else
                    failed=$((failed + 1))
                fi
            done
            ;;
        work)
            for key in $SSA_WORK_KEYS; do
                if _ssa_add_key "$key" "work ($(basename "$key"))"; then
                    added=$((added + 1))
                else
                    failed=$((failed + 1))
                fi
            done
            ;;
        all)
            start_ssh_agent personal
            local rc1=$?
            start_ssh_agent work
            local rc2=$?
            return $((rc1 || rc2))
            ;;
        -h|--help|help)
            echo "usage: ssa [personal|work|all|/path/to/key]"
            return 0
            ;;
        *)
            # Explicit key path: ssa ~/.ssh/my-key (missing file -> clean skip, not "unknown")
            case "$profile" in
                */*|~*|.*)
                    _ssa_add_key "$profile" "$(basename "$profile")"
                    return $?
                    ;;
            esac
            if [ -f "$profile" ]; then
                _ssa_add_key "$profile" "$(basename "$profile")"
                return $?
            fi
            echo "ssa: unknown profile '$profile' (expected personal|work|all|/path/to/key)" >&2
            return 2
            ;;
    esac
    if [ "$added" -eq 0 ] && [ "$failed" -gt 0 ]; then
        echo "ssa: no keys added (missing files? check SSA_*_KEYS paths)" >&2
        return 1
    fi
    return 0
}

# ===========================
# Colored output for ls, grep, etc.
# ===========================
if [ -x /usr/bin/dircolors ]; then
    eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias dir='dir --color=auto'
    alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# opencode
export PATH=$USERPROFILE/.opencode/bin:$PATH

export PS1="[\[$(tput sgr0)\]\[\033[0;35m\]\u\[$(tput sgr0)\]][\[$(tput sgr0)\]\[\033[0;36m\]\A\[$(tput sgr0)\]][\[$(tput sgr0)\]\[\033[0;32m\\]\w\[$(tput sgr0)\]]\[\e[31m\]\`git_branch\`\n\[$(tput sgr0)\]\[\033[0;31m\]>>\[$(tput sgr0)\] : \[$(tput sgr0)\]"

# cd to home if shell opened in a system directory
case "$PWD" in
  /c/WINDOWS*|/c/windows*) cd "$HOME" ;;
esac

# Kill visual bell flash (DECSCNM) on boundary keypresses
bind 'set bell-style none'

# Pi
export PATH="C:\Program Files\nodejs/bin:$PATH"

export PATH="$HOME/.local/bin:$PATH"
