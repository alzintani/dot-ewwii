#!/bin/bash

get_window_title() {
  if [ -n "$SWAYSOCK" ] || [ "$XDG_CURRENT_DESKTOP" = "sway" ]; then
    swaymsg -t get_tree | jq -r '.. | select(.focused? == true).name'
  elif [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
    hyprctl activewindow -j | jq -r '.title'
  elif [ -n "$NIRI_SOCKET" ]; then
    title=$(niri msg --json focused-window 2>/dev/null | jq -r '.title' 2>/dev/null)
    if [ -z "$title" ] || [ "$title" = "null" ]; then
      title=$(niri msg --json windows 2>/dev/null | jq -r '.[] | select(.is_focused) | .title' 2>/dev/null)
    fi
    echo "$title"
  elif command -v mmsg >/dev/null 2>&1; then
    mmsg get focusing-client 2> /dev/null | jq -r '.title // "..."'
    # mmsg -g -c 2>/dev/null | grep "title" | cut -d' ' -f3-
  else
    echo "Unknown Compositor"
  fi
}

get_workspace_active() {
  if [ -n "$SWAYSOCK" ] || [ "$XDG_CURRENT_DESKTOP" = "sway" ]; then
    swaymsg -t get_workspaces | jq -r '.[] | select(.focused == true).name'
  elif [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
    hyprctl activeworkspace -j | jq -r '.id'
  elif [ -n "$NIRI_SOCKET" ]; then
    niri msg --json workspaces 2>/dev/null | jq -r '.[] | select(.is_focused) | .idx'
  elif command -v mmsg >/dev/null 2>&1; then
    # mmsg -g -t 2>/dev/null | grep "tag [0-9] 1" | head -1 | awk '{print $3}'
    mmsg get all-tags | jq -r ".. | select(.is_active? == true) | .index"
  else
    echo "Unknown Compositor"
  fi
}

get_volume_value() {
  if command -v wpctl >/dev/null 2>&1; then
    wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2 * 100)}'
  elif command -v pactl >/dev/null 2>&1; then
    pactl get-sink-volume @DEFAULT_SINK@ | grep -Po '\d+(?=%)' | head -1
  elif command -v amixer >/dev/null 2>&1; then
    amixer get Master | grep -Po '\[\d+%\]' | head -1 | tr -d '[]%'
  else
    echo "N/A"
  fi
}

get_scss_var() {
  if [ -n "$1" ]; then
    grep -oP "(?<=$1:\s)[^;]+" ~/.config/ewwii/scss/variables.scss | tr -d ' \t\n'
  fi
}

set_scss_var() {
  if [ -n "$1" ] && [ -n "$2" ]; then
    if [ "color-schemes" = "$1" ]; then
      sed -i "s|@import \"color-schemes/.*\";|@import \"color-schemes/$2\";|g" ~/.config/ewwii/scss/variables.scss
    else
      sed -i "s/\$$1: .*;/\$$1: $2;/" ~/.config/ewwii/scss/variables.scss
    fi
  fi
}

run_go_to() {
  if [ -n "$SWAYSOCK" ] || [ "$XDG_CURRENT_DESKTOP" = "sway" ]; then
    swaymsg workspace number $1
  elif [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
    echo ""
  elif [ -n "$NIRI_SOCKET" ]; then
    echo ""
  elif command -v mmsg >/dev/null 2>&1; then
    # mmsg -t $1
    mmsg dispatch view,$1
  else
    echo "Unknown Compositor"
  fi

  ewwii update active_workspace=$1
}

if [ -n "$1" ]; then
  if [ "get" = "$1" ]; then
    case "$2" in
      "window-title")
        get_window_title
        ;;
      "workspace-active")
        get_workspace_active
        ;;
      "volum-value")
        get_volume_value
        ;;
      "scss-var")
        get_scss_var $3
        ;;
      *)
        echo "Usage: $0 get {window-title | workspace-active | volum-value | font-scale}"
        exit 1
        ;;
    esac
  elif [ "set" = "$1" ]; then
    case "$2" in
      "scss-var")
        set_scss_var $3 $4
        ;;
      *)
        echo "Usage: $0 set {window_title | workspace_active | volum_value | font_scale}"
        exit 1
        ;;
    esac
  elif [ "run" = "$1" ]; then
    case "$2" in
      "go-to")
        run_go_to $3
        ;;
      *)
        echo "Usage: $0 run {go_to}"
        exit 1
        ;;
    esac
  else
    echo "Usage: $0 {get | set} command"
  fi
else
  echo "Usage: $0 {get | set} command"
fi

