#!/usr/bin/env bash
#
# Symlink the nvim and Zed configs in this repo into their macOS/Linux locations.
#
# For each config: if the target path is already the correct symlink, it is left
# alone. If a real file or directory is there, it is RENAMED to a .bak (never
# deleted) and replaced with a symlink into this repo.
#
# Safe to re-run. Existing backups are never overwritten - a second run that
# finds one already present adds a timestamp instead.
#
# Usage:
#   ./bootstrap.sh --dry-run
#   ./bootstrap.sh

set -euo pipefail

DRY_RUN=0
case "${1:-}" in
    --dry-run|-n) DRY_RUN=1 ;;
    '') ;;
    *) echo "usage: $0 [--dry-run]" >&2; exit 2 ;;
esac

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Zed and nvim both use XDG paths on macOS and Linux. (Zed keeps its *state*
# elsewhere - ~/Library/Application Support/Zed on macOS - but config is here.)
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

# link path | repo target | dir?
LINKS=(
    "$CONFIG_HOME/nvim|$REPO/nvim|dir"
    "$CONFIG_HOME/zed/settings.json|$REPO/zed/settings.json|file"
    "$CONFIG_HOME/zed/keymap.json|$REPO/zed/keymap.json|file"
    "$CONFIG_HOME/zed/AGENTS.md|$REPO/zed/AGENTS.md|file"
)

if [ -t 1 ]; then
    RED=$'\033[31m'; GRN=$'\033[32m'; YEL=$'\033[33m'; CYN=$'\033[36m'; RST=$'\033[0m'
else
    RED=''; GRN=''; YEL=''; CYN=''; RST=''
fi

tilde() { printf '%s' "${1/#$HOME/\~}"; }

# ------------------------------------------------------------------ preflight
printf '\n%s== Preflight ==%s\n' "$CYN" "$RST"

missing=0
for entry in "${LINKS[@]}"; do
    IFS='|' read -r _ target _ <<< "$entry"
    if [ ! -e "$target" ]; then
        printf '  %sFAIL%s missing in repo: %s\n' "$RED" "$RST" "$target"
        missing=1
    fi
done
if [ "$missing" -eq 1 ]; then
    echo "  Is this script running from inside the dotfiles repo?" >&2
    exit 1
fi
printf '  %sok%s      all %d sources present in repo\n' "$GRN" "$RST" "${#LINKS[@]}"

# A running editor can hold the config open; not fatal on POSIX the way it is on
# Windows, but a live nvim will keep using its old config until restarted.
if pgrep -x nvim >/dev/null 2>&1 || pgrep -ix zed >/dev/null 2>&1; then
    printf '  %swarn%s    nvim or Zed is running - restart it afterwards to pick up changes\n' "$YEL" "$RST"
else
    printf '  %sok%s      no Zed or nvim processes running\n' "$GRN" "$RST"
fi

[ "$DRY_RUN" -eq 1 ] && printf '  %sDRY RUN - nothing will be modified%s\n' "$YEL" "$RST"

# ---------------------------------------------------------------------- link
printf '\n%s== Linking ==%s\n' "$CYN" "$RST"

for entry in "${LINKS[@]}"; do
    IFS='|' read -r link target kind <<< "$entry"
    name="$(tilde "$link")"

    if [ -L "$link" ]; then
        current="$(readlink "$link")"
        if [ "$current" = "$target" ]; then
            printf '  %sok%s      %s (already linked)\n' "$GRN" "$RST" "$name"
            continue
        fi
        printf '  %srelink%s  %s (was -> %s)\n' "$YEL" "$RST" "$name" "$current"
        # rm on a symlink removes the link, never the target's contents.
        [ "$DRY_RUN" -eq 0 ] && rm "$link"
    elif [ -e "$link" ]; then
        bak="$link.pre-dotfiles.bak"
        if [ -e "$bak" ]; then
            bak="$link.pre-dotfiles-$(date +%Y%m%d-%H%M%S).bak"
        fi
        printf '  %sbackup%s  %s -> %s\n' "$YEL" "$RST" "$name" "$(basename "$bak")"
        [ "$DRY_RUN" -eq 0 ] && mv "$link" "$bak"
    fi

    parent="$(dirname "$link")"
    if [ ! -d "$parent" ]; then
        printf '  mkdir   %s\n' "$(tilde "$parent")"
        [ "$DRY_RUN" -eq 0 ] && mkdir -p "$parent"
    fi

    printf '  %slink%s    %s -> <repo>%s\n' "$GRN" "$RST" "$name" "${target#$REPO}"
    [ "$DRY_RUN" -eq 0 ] && ln -s "$target" "$link"
done

# -------------------------------------------------------------------- verify
if [ "$DRY_RUN" -eq 1 ]; then
    printf '\nDry run complete. Re-run without --dry-run to apply.\n\n'
    exit 0
fi

printf '\n%s== Verify ==%s\n' "$CYN" "$RST"
bad=0
for entry in "${LINKS[@]}"; do
    IFS='|' read -r link target kind <<< "$entry"
    name="$(tilde "$link")"

    if [ ! -L "$link" ] || [ "$(readlink "$link")" != "$target" ]; then
        printf '  %sFAIL%s    %s\n' "$RED" "$RST" "$name"; bad=$((bad + 1))
    elif [ "$kind" = dir ] && [ ! -r "$link/init.lua" ]; then
        printf '  %sFAIL%s    %s (link resolves but init.lua unreadable)\n' "$RED" "$RST" "$name"; bad=$((bad + 1))
    elif [ "$kind" = file ] && ! cmp -s "$link" "$target"; then
        printf '  %sFAIL%s    %s (content differs through link)\n' "$RED" "$RST" "$name"; bad=$((bad + 1))
    else
        printf '  %sok%s      %s\n' "$GRN" "$RST" "$name"
    fi
done

if [ "$bad" -gt 0 ]; then
    printf '\n%s%d link(s) failed verification%s\n\n' "$RED" "$bad" "$RST"
    exit 1
fi
printf '\n%sAll %d links verified. Backups kept as *.pre-dotfiles.bak%s\n\n' "$GRN" "${#LINKS[@]}" "$RST"
