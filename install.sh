#!/bin/bash
set -euo pipefail

# ===================================================================
#  dotfiles installer – creates symlinks from normal application
#  paths back into this repository.  Run --help for details.
# ===================================================================

REPO_URL="https://github.com/erikjoachim/dotfiles.git"
BOOTSTRAP_DIR="$HOME/dotfiles"

# ---- flags ----
DRY_RUN=false
VERIFY=false
UNINSTALL=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run) DRY_RUN=true  ; shift ;;
        --verify)  VERIFY=true   ; shift ;;
        --uninstall) UNINSTALL=true ; shift ;;
            --help|-h)
                echo "Usage: $0 [--dry-run] [--verify] [--uninstall]"
                echo "  (no flag)   Normal install – create symlinks"
                echo "  --dry-run   Show actions without making changes"
                echo "  --verify    Check every entry; exit 1 on failure"
                echo "  --uninstall Remove managed symlinks"
            exit 0
            ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

# ---- helpers ----
log() {
    local kind="$1" msg="$2"
    case "$kind" in
        INFO)   echo -e "[INFO] $msg" ;;
        OK)     echo -e "[OK]   $msg" ;;
        SKIP)   echo -e "[SKIP] $msg" ;;
        LINK)   echo -e "[LINK] $msg" ;;
        UNLINK) echo -e "[UNLINK] $msg" ;;
        REMOVE) echo -e "[REMOVE] $msg" ;;
        ERROR)  echo -e "[ERROR] $msg" ;;
        DRY)    echo -e "[DRY]   $msg" ;;
        *)      echo -e "[$kind] $msg" ;;
    esac
}

dry() {
    $DRY_RUN
}

expand_path() {
    local path="$1"
    # Expand ~ at start (case patterns don't expand tilde in MSYS2/Git Bash)
    if [[ "$path" =~ ^~/(.*)$ ]]; then
        path="$HOME/${BASH_REMATCH[1]}"
    elif [[ "$path" == "~" ]]; then
        path="$HOME"
    fi
    # Expand %VARNAME% env vars
    while [[ "$path" =~ %([A-Za-z_][A-Za-z0-9_]*)% ]]; do
        local var="${BASH_REMATCH[1]}"
        local val="${!var:-}"
        path="${path//%${var}%/${val}}"
    done
    printf '%s' "$path"
}

get_platform() {
    case "$(uname -s)" in
        Linux*)  printf linux ;;
        Darwin*) printf macos ;;
        MINGW*|MSYS*|CYGWIN*) printf windows ;;
        *)       printf unknown ;;
    esac
}

# Resolve symlink target, or empty string if not a symlink
symlink_target() {
    local path="$1"
    if [[ -L "$path" ]]; then
        readlink "$path"
    fi
}

create_symlink() {
    local src="$1" dst="$2"
    if [[ "$(get_platform)" == "windows" ]]; then
        MSYS=winsymlinks:nativestrict ln -sf "$src" "$dst"
    else
        ln -sf "$src" "$dst"
    fi
}

canonicalize() {
    local path="$1"
    # resolve to canonical absolute path; return empty if unresolvable
    readlink -f "$path" 2>/dev/null || realpath "$path" 2>/dev/null || {
        local dir; dir="$(dirname "$path")" 2>/dev/null || return 1
        local base; base="$(basename "$path")" 2>/dev/null || return 1
        (cd "$dir" 2>/dev/null && echo "$(pwd -P)/$base") 2>/dev/null || true
    }
}

# Resolve what a symlink points to (absolute canonical path)
# Handles both absolute and relative link targets.
resolve_link() {
    local link_path="$1"
    local target
    target="$(symlink_target "$link_path")" || return 1
    [[ -z "$target" ]] && return 1
    if [[ "$target" == /* ]]; then
        canonicalize "$target" 2>/dev/null || true
    else
        canonicalize "$(dirname "$link_path")/$target" 2>/dev/null || true
    fi
}

# ---- YAML parser (awk) ----
parse_manifest() {
    local manifest="$1" platform
    platform=$(get_platform)
    awk -v platform="$platform" '
    BEGIN { entry=0; src=""; tgt=""; platforms="" }
    /^  - source:/ {
        if (entry && src != "" && tgt != "") print_entry()
        entry=1; src=""; tgt=""; platforms=""
        sub(/^  - source: /, ""); src=$0
    }
    /^    target: / {
        sub(/^    target: /, ""); tgt=$0
    }
    /^    platforms: / {
        sub(/^    platforms: \[/, ""); sub(/\]/, ""); platforms=$0
        gsub(/ /, "", platforms)
    }
    /^[[:space:]]*$/ && entry {
        print_entry()
        entry=0
    }
    END { if (entry) print_entry() }
    function in_platforms() {
        if (platforms == "") return 1
        n = split(platforms, arr, ",")
        for (i = 1; i <= n; i++) if (arr[i] == platform) return 1
        return 0
    }
    function print_entry() {
        if (in_platforms()) print src "|" tgt
    }
    ' "$manifest"
}

# ---- bootstrap ----
bootstrap() {
    log INFO "Dotfiles directory not detected – cloning to $BOOTSTRAP_DIR"

    if [[ -d "$BOOTSTRAP_DIR" && -n "$(ls -A "$BOOTSTRAP_DIR" 2>/dev/null)" ]]; then
        log ERROR "Target $BOOTSTRAP_DIR exists and is not empty – aborting bootstrap"
        log INFO "Remove or rename it first, or run install from a cloned copy"
        exit 1
    fi

    if ! command -v git &>/dev/null; then
        log ERROR "git is required for bootstrap mode"
        exit 1
    fi

    if ! dry; then
        git clone "$REPO_URL" "$BOOTSTRAP_DIR"
        log OK "Cloned to $BOOTSTRAP_DIR"
    else
        log DRY "Would clone $REPO_URL -> $BOOTSTRAP_DIR"
    fi

    local child="$BOOTSTRAP_DIR/install.sh"
    if [[ -f "$child" ]]; then
        local args=()
        $DRY_RUN   && args+=(--dry-run)
        $VERIFY    && args+=(--verify)
        $UNINSTALL && args+=(--uninstall)
        exec "$child" "${args[@]}"
    fi
}

# ---- verify ----
verify() {
    local repo_root="$1" manifest="$2"
    local all_ok=true

    while IFS='|' read -r rel_src raw_tgt; do
        local src="$(canonicalize "$repo_root/$rel_src")"
        local dst="$(expand_path "$raw_tgt")"

        # source exists
        if [[ ! -f "$src" ]]; then
            log ERROR "MISSING SOURCE: $rel_src"
            all_ok=false; continue
        fi

        # destination exists
        if [[ ! -e "$dst" && ! -L "$dst" ]]; then
            log ERROR "MISSING LINK: $dst"
            all_ok=false; continue
        fi

        # is symlink
        local target
        target="$(symlink_target "$dst")"
        if [[ -z "$target" ]]; then
            if [[ -L "$dst" ]]; then
                log ERROR "BROKEN LINK: $dst"
            else
                log ERROR "REGULAR FILE (not a symlink): $dst"
            fi
            all_ok=false; continue
        fi

        # points to correct source
        local resolved_target resolved_src
        resolved_target="$(resolve_link "$dst" 2>/dev/null || true)"
        resolved_src="$(canonicalize "$src" 2>/dev/null || true)"

        if [[ -z "$resolved_target" || -z "$resolved_src" ]]; then
            log ERROR "BROKEN LINK: $dst -> $target"
            all_ok=false; continue
        fi

        if [[ "$resolved_target" != "$resolved_src" ]]; then
            log ERROR "WRONG TARGET: $dst -> $resolved_target (expected $resolved_src)"
            all_ok=false; continue
        fi

        log OK "$rel_src -> $dst"
    done < <(parse_manifest "$manifest")

    $all_ok && log OK "All entries verified successfully"
    $all_ok
}

# ---- uninstall ----
uninstall_links() {
    local repo_root="$1" manifest="$2"

    while IFS='|' read -r rel_src raw_tgt; do
        local src="$(canonicalize "$repo_root/$rel_src")"
        local dst="$(expand_path "$raw_tgt")"

        if [[ ! -e "$dst" && ! -L "$dst" ]]; then
            log SKIP "Not installed: $dst"
            continue
        fi

        local target
        target="$(symlink_target "$dst")"
        if [[ -z "$target" ]]; then
            log SKIP "Regular file (not ours): $dst"
            continue
        fi

        local resolved_target
        resolved_target="$(resolve_link "$dst" 2>/dev/null || true)"
        if [[ -n "$resolved_target" && "$resolved_target" == "$(canonicalize "$src" 2>/dev/null || true)" ]]; then
            if ! dry; then
                rm "$dst"
                log REMOVE "Removed: $dst"
            else
                log DRY "Would remove: $dst"
            fi
        else
            log SKIP "Symlink not pointing to repo: $dst -> $target"
        fi
    done < <(parse_manifest "$manifest")
}

# ---- install ----
install_dotfile() {
    local src="$1" dst="$2"

    # Ensure parent directory exists
    local parent
    parent="$(dirname "$dst")"
    if [[ ! -d "$parent" ]]; then
        if ! dry; then
            mkdir -p "$parent"
            log INFO "Created directory $parent"
        else
            log DRY "Would create directory $parent"
        fi
    fi

    # Destination path exists
    if [[ -e "$dst" || -L "$dst" ]]; then
        local target
        target="$(symlink_target "$dst")"

        if [[ -n "$target" ]]; then
            # It's a symlink – check if correct
            local resolved_target resolved_src
            resolved_target="$(resolve_link "$dst" 2>/dev/null || true)"
            resolved_src="$(canonicalize "$src" 2>/dev/null || true)"

            if [[ -n "$resolved_target" && -n "$resolved_src" && "$resolved_target" == "$resolved_src" ]]; then
                log SKIP "Already correct: $dst"
                return
            fi

            # Wrong or broken link – remove
            if ! dry; then
                rm "$dst"
                log LINK "Removed incorrect link: $dst"
            else
                log DRY "Would remove incorrect link: $dst"
            fi
        else
            # Regular file – remove it (repo is source of truth)
            if ! dry; then
                rm "$dst"
                log REMOVE "Removed regular file: $dst"
            else
                log DRY "Would remove regular file: $dst"
            fi
        fi
    fi

    # Create symlink
    if ! dry; then
        create_symlink "$src" "$dst"
        log LINK "Linked: $dst -> $src"
    else
        log DRY "Would link: $dst -> $src"
    fi
}

# ===================================================================
# MAIN
# ===================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MANIFEST="$SCRIPT_DIR/dotfiles.yaml"

# bootstrap
if [[ ! -f "$MANIFEST" ]]; then
    bootstrap
    exit 0
fi

if $VERIFY; then
    verify "$SCRIPT_DIR" "$MANIFEST" && exit 0 || exit 1
fi

if $UNINSTALL; then
    uninstall_links "$SCRIPT_DIR" "$MANIFEST"
    exit 0
fi

# install
while IFS='|' read -r rel_src raw_tgt; do
    src="$SCRIPT_DIR/$rel_src"
    dst="$(expand_path "$raw_tgt")"

    if [[ ! -f "$src" ]]; then
        log ERROR "Source file missing: $src"
        continue
    fi

    install_dotfile "$src" "$dst"
done < <(parse_manifest "$MANIFEST")

log OK "Done"
