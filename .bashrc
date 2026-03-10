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
alias cdinit="cd </c/path/to/your/pref/projects/folder>"
alias exp="explorer ."

# Colors
BLUE="\033[1;34m"
GREEN="\033[1;32m"
RESET="\033[0m"

lt() {
    for f in *; do
        if [ -d "$f" ]; then
            printf "${BLUE}%s/${RESET}\n" "$f"
        else
            printf "${GREEN}%s${RESET}\n" "$f"
        fi
    done
}

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
alias gh="git log --pretty=format:'%C(yellow)[%ad]%C(reset) %C(green)[%h]%C(reset) | %C(red)%s %C(bold red){{%an}}%C(reset) %C(blue)%d%C(reset)' --graph --date=short"
alias gh2="git log --graph --pretty=format:'%C(auto)%h %s%C(reset)' --abbrev-commit"
alias gh-premium="git log --graph --abbrev-commit --decorate --pretty=format:'%C(auto)%h%C(reset) %C(bold)%s%C(reset)%C(dim white) · %an%C(reset)%C(yellow)%d%C(reset)'"
alias gh-dates="git log --graph --abbrev-commit --decorate --date=short --pretty=format:'%C(auto)%h%C(reset) %C(white)%s%C(reset) %C(dim white)%ad%C(reset)%C(yellow)%d%C(reset)'"
alias gs="git status"
alias gd="git diff"
alias gp="git pull"
alias gc="git checkout"
alias ga="git add"
alias gaa="git add . && git status"
alias gr="git restore"
alias gcm="git commit -m"
alias gcom="git commit"
git_branch() {
     git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}

# ===========================
# Tools aliases
# ===========================
alias oc="opencode"

# ===========================
# Function: Start ssh-agent for personal projects
# ===========================
alias ssa="start_ssh_agent"

start_ssh_agent() {
    local key="$HOME/.ssh/id_ed25519_personal"

    # Start ssh-agent if not running
    if [ -z "$SSH_AUTH_SOCK" ]; then
        eval "$(ssh-agent -s)"
    fi

    # Add personal key if not already added
    if ssh-add -l | grep -q "$(ssh-keygen -lf "$key" | awk '{print $2}')" ; then
        echo "Personal SSH key already added."
    else
        ssh-add "$key"
        echo "Personal SSH key added to ssh-agent."
    fi
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

export PS1="[\[$(tput sgr0)\]\[\033[0;35m\]\u\[$(tput sgr0)\]][\[$(tput sgr0)\]\[\033[0;36m\]\A\[$(tput sgr0)\]][\[$(tput sgr0)\]\[\033[0;32m\\]\w\[$(tput sgr0)\]]\e[31m\]\`git_branch\`\n\[$(tput sgr0)\]\[\033[0;31m\]>>\[$(tput sgr0)\] : \[$(tput sgr0)\]"
