#!/usr/bin/env bash
# theme: switch the whole desktop theme in one go.
#
#   theme                 pick from a list (fzf if installed)
#   theme <name>          apply themes/<name>.theme
#   theme next            cycle to the next theme
#   theme toggle          jump to the last-used theme of the opposite light/dark appearance
#   theme wallpaper       next wallpaper from the current theme's list
#   theme restore         re-apply the current theme (used after a fresh install)
#   theme list | current
#
# Themes are plain files in themes/*.theme, so adding one never touches this script.
# Written for macOS bash 3.2: no associative arrays, no `sed -i ''`.

# Deliberately no `set -e`: one app failing must not stop the rest from switching.
set -uo pipefail

# --- locate the repo, even when invoked through a symlink (~/.local/bin/theme) ---
SELF="${BASH_SOURCE[0]}"
while [ -L "$SELF" ]; do
  _dir="$(cd "$(dirname "$SELF")" && pwd)"
  SELF="$(readlink "$SELF")"
  case "$SELF" in /*) ;; *) SELF="$_dir/$SELF" ;; esac
done
DOTFILES_DIR="$(cd "$(dirname "$SELF")/.." && pwd)"
export DOTFILES_DIR

THEMES_DIR="$DOTFILES_DIR/themes"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/theme"
CFG="$HOME/.config"
DEFAULT_THEME="white"

GHOSTTY_DIR="$CFG/ghostty"
ZED_CONF="$CFG/zed/settings.json"

# --- tiny output helpers ---
if [ -t 1 ]; then _g=$'\033[32m'; _y=$'\033[33m'; _d=$'\033[2m'; _r=$'\033[0m'; else _g=""; _y=""; _d=""; _r=""; fi
ok()   { printf '  %s✓%s %-10s %s\n' "$_g" "$_r" "$1" "${2:-}"; }
skip() { printf '  %s-%s %-10s %s%s%s\n' "$_d" "$_r" "$1" "$_d" "${2:-not installed}" "$_r"; }
warn() { printf '  %s!%s %-10s %s\n' "$_y" "$_r" "$1" "${2:-}"; }

# Run a command but give up after N seconds, so one stuck app can never hang the whole switch.
# (macOS ships no `timeout`.) Returns 124 on timeout.
run_timeout() {
  local secs="$1" pid i=0; shift
  "$@" &
  pid=$!
  while kill -0 "$pid" 2>/dev/null; do
    if [ "$i" -ge $((secs * 10)) ]; then
      kill "$pid" 2>/dev/null; wait "$pid" 2>/dev/null
      return 124
    fi
    sleep 0.1; i=$((i + 1))
  done
  wait "$pid"
}

# --- theme files ---
list_themes() {
  local f
  for f in "$THEMES_DIR"/*.theme; do
    [ -e "$f" ] && basename "$f" .theme
  done
}

current_theme() { cat "$STATE_DIR/current" 2>/dev/null || true; }

# Source a theme into the current shell, after clearing the previous one.
load_theme() {
  local file="$THEMES_DIR/$1.theme"
  [ -f "$file" ] || { echo "Unknown theme: $1 (try: theme list)" >&2; return 1; }
  unset LABEL APPEARANCE GHOSTTY_THEME ZED_THEME ACCENT ACCENT_ALPHA
  WALLPAPERS=()
  # shellcheck disable=SC1090
  . "$file"
  LABEL="${LABEL:-$1}"
  APPEARANCE="${APPEARANCE:-dark}"
  ACCENT_ALPHA="${ACCENT_ALPHA:-ff}"
  case "${ACCENT:-}" in
    [0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]) ;;
    *) echo "themes/$1.theme: ACCENT must be 6 hex digits, e.g. cba6f7" >&2; return 1 ;;
  esac
}

# One-line summary per theme for the picker / `theme list`.
describe_themes() {
  local t cur; cur="$(current_theme)"
  for t in $(list_themes); do
    ( load_theme "$t" 2>/dev/null && \
      printf '%s %-20s %s (%s)\n' "$([ "$t" = "$cur" ] && echo '*' || echo ' ')" "$t" "$LABEL" "$APPEARANCE" )
  done
}

# --- per-app appliers. Each one skips quietly if the app isn't set up. ---

apply_ghostty() {
  [ -d "$GHOSTTY_DIR" ] || { skip ghostty; return; }
  # Written to a git-ignored include so switching themes never dirties the repo.
  # A theme with no GHOSTTY_THEME gets an empty include, i.e. Ghostty's built-in default colours.
  if [ -n "${GHOSTTY_THEME:-}" ]; then
    printf 'theme = %s\n' "$GHOSTTY_THEME" > "$GHOSTTY_DIR/theme.local"
  else
    printf '# no theme: Ghostty defaults\n' > "$GHOSTTY_DIR/theme.local"
  fi
  if ! grep -qs 'theme.local' "$GHOSTTY_DIR/config"; then
    warn ghostty "add 'config-file = ?theme.local' to ghostty/config"; return
  fi
  pkill -USR2 -x ghostty 2>/dev/null   # live reload on recent Ghostty; otherwise press Cmd+Shift+,
  ok ghostty "${GHOSTTY_THEME:-default colours}"
}

apply_borders() {
  command -v borders >/dev/null 2>&1 || { skip borders; return; }
  # `borders <options>` with no daemon running STARTS a daemon in the foreground and never returns,
  # so only send the update if one is already running. bordersrc picks the colour up on next start.
  if ! pgrep -x borders >/dev/null 2>&1; then
    skip borders "not running (colour applies when it starts)"; return
  fi
  if run_timeout 3 borders active_color="$BORDER_COLOR" >/dev/null 2>&1; then
    ok borders "$BORDER_COLOR"
  else
    warn borders "no response; try: brew services restart borders"
  fi
}

apply_zed() {
  [ -f "$ZED_CONF" ] || { skip zed; return; }
  [ -n "${ZED_THEME:-}" ] || { skip zed "no ZED_THEME in theme"; return; }
  # Edits only the "theme": {...} block in place, so comments and formatting survive.
  # (The old version re-parsed the file as JSON and silently wrote {} if parsing failed.)
  ZED_MODE="$APPEARANCE" ZED_NAME="$ZED_THEME" perl -0pi -e '
    s!("theme"\s*:\s*\{)([^}]*)(\})!
      my ($a, $b, $c) = ($1, $2, $3);
      my ($m, $t) = ($ENV{ZED_MODE}, $ENV{ZED_NAME});
      $b =~ s/("mode"\s*:\s*)"[^"]*"/$1"$m"/;
      $b =~ s/("\Q$m\E"\s*:\s*)"[^"]*"/$1"$t"/;
      $a . $b . $c;
    !e;
  ' "$ZED_CONF"
  if grep -qF "\"$ZED_THEME\"" "$ZED_CONF"; then
    ok zed "$ZED_THEME ($APPEARANCE)"
  else
    warn zed "settings.json needs a \"theme\": {mode, light, dark} block"
  fi
}

apply_macos() {
  command -v osascript >/dev/null 2>&1 || { skip appearance "not macOS"; return; }
  local now want
  now="$(defaults read -g AppleInterfaceStyle 2>/dev/null || echo Light)"
  want="Light"; [ "$APPEARANCE" = "dark" ] && want="Dark"
  if [ "$now" = "$want" ]; then
    ok appearance "already $want"
  else
    run_timeout 15 osascript -e "tell application \"System Events\" to tell appearance preferences to set dark mode to $([ "$want" = Dark ] && echo true || echo false)" \
      && ok appearance "$want" || warn appearance "osascript failed or timed out (check Automation permission)"
  fi
}

# WALLPAPERS is an array in the theme file. The first is used when the theme is applied;
# `theme wallpaper` steps through the rest. Index is kept in the state dir.
apply_wallpaper() {
  local n=${#WALLPAPERS[@]} i f
  [ "$n" -gt 0 ] || return 0
  command -v osascript >/dev/null 2>&1 || return 0
  i="$(cat "$STATE_DIR/wallpaper-index" 2>/dev/null || echo 0)"
  case "$i" in ''|*[!0-9]*) i=0 ;; esac
  i=$((i % n)); f="${WALLPAPERS[$i]}"
  [ -f "$f" ] || { warn wallpaper "not found: $f"; return; }
  run_timeout 15 osascript -e 'on run argv' \
            -e 'tell application "System Events" to tell every desktop to set picture to (item 1 of argv)' \
            -e 'end run' "$f" && ok wallpaper "$(basename "$f") ($((i + 1))/$n)" \
    || warn wallpaper "osascript failed or timed out"
}

# --- apply a named theme ---
apply_theme() {
  local name="$1"
  load_theme "$name" || return 1

  # Accent colour -> JankyBorders' 0xAARRGGBB.
  local hex; hex="$(printf '%s' "$ACCENT" | tr 'A-F' 'a-f')"
  BORDER_COLOR="0x${ACCENT_ALPHA}${hex}"

  # State lives outside the repo: what bordersrc reads, and what next/toggle/restore use.
  mkdir -p "$STATE_DIR"
  printf 'BORDER_COLOR=%s\nTHEME_NAME=%s\n' "$BORDER_COLOR" "$name" > "$STATE_DIR/env"
  printf '%s\n' "$name" > "$STATE_DIR/current"
  printf '%s\n' "$name" > "$STATE_DIR/last-$APPEARANCE"
  printf '0\n' > "$STATE_DIR/wallpaper-index"

  printf 'Applying %s%s%s (%s)\n' "$_g" "$LABEL" "$_r" "$APPEARANCE"
  apply_ghostty
  apply_borders
  apply_zed
  apply_macos
  apply_wallpaper
  return 0
}

# --- commands ---
pick_theme() {
  local choice
  if command -v fzf >/dev/null 2>&1; then
    choice="$(describe_themes | fzf --prompt='theme > ' --height=~40% --reverse | awk '{print ($1=="*") ? $2 : $1}')"
  else
    local names; names="$(list_themes)"
    local PS3="Theme number: "
    select choice in $names; do break; done
  fi
  [ -n "${choice:-}" ] && apply_theme "$choice"
}

cycle_next() {
  local cur first="" t found=0
  cur="$(current_theme)"
  for t in $(list_themes); do
    [ -z "$first" ] && first="$t"
    if [ "$found" = 1 ]; then apply_theme "$t"; return; fi
    [ "$t" = "$cur" ] && found=1
  done
  apply_theme "$first"
}

toggle_appearance() {
  local cur cur_app other t
  cur="$(current_theme)"
  if [ -n "$cur" ] && load_theme "$cur" 2>/dev/null; then cur_app="$APPEARANCE"; else cur_app="light"; fi
  other="dark"; [ "$cur_app" = "dark" ] && other="light"
  # Prefer whatever you last used in the other appearance.
  t="$(cat "$STATE_DIR/last-$other" 2>/dev/null || true)"
  if [ -z "$t" ] || [ ! -f "$THEMES_DIR/$t.theme" ]; then
    for t in $(list_themes); do
      ( load_theme "$t" 2>/dev/null && [ "$APPEARANCE" = "$other" ] ) && break
      t=""
    done
  fi
  if [ -n "$t" ]; then apply_theme "$t"; else echo "No $other theme found in $THEMES_DIR" >&2; fi
}

cycle_wallpaper() {
  local cur; cur="$(current_theme)"
  [ -n "$cur" ] && load_theme "$cur" || { echo "No current theme. Run: theme <name>" >&2; return 1; }
  local i; i="$(cat "$STATE_DIR/wallpaper-index" 2>/dev/null || echo 0)"
  case "$i" in ''|*[!0-9]*) i=0 ;; esac
  printf '%s\n' "$((i + 1))" > "$STATE_DIR/wallpaper-index"
  apply_wallpaper
}

usage() { sed -n '2,11p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

case "${1:-}" in
  "")            pick_theme ;;
  -h|--help|help) usage ;;
  list|ls)       describe_themes ;;
  current)       current_theme ;;
  next)          cycle_next ;;
  toggle)        toggle_appearance ;;
  wallpaper|wp)  cycle_wallpaper ;;
  restore)       apply_theme "$(current_theme | grep . || echo "$DEFAULT_THEME")" ;;
  *)             apply_theme "$1" ;;
esac
