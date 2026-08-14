#!/bin/bash

set -e

config_file="$HOME/.config/sway_win_extra"
rm -f "$config_file"

wallpaper_file="$HOME/images/wallpapers/cityscape_synthwave_moon_buildings_4k_hd_vaporwave.jpg"

# One line per active output: name, identifier, and its highest mode
# (largest area, then highest refresh; refresh is reported in mHz)
displays="$(swaymsg -t get_outputs | jq -r '
    .[] | select(.active == true) |
    (.modes | max_by([.width * .height, .refresh])) as $m |
    [.name, .make + " " + .model + " " + .serial,
     $m.width, $m.height, $m.refresh] | @tsv')"

# First pass: set each output to its highest resolution and DPI scale
declare -A out_scale out_width out_height
while IFS=$'\t' read -r name identifier width height refresh; do
    if [ "$name" = "eDP-1" ]; then
        scale=2.0
    elif [ "$width" -ge 3840 ]; then
        scale=1.5
    else
        scale=1.0
    fi
    hz="$(awk -v r="$refresh" 'BEGIN { printf "%.3f", r / 1000 }')"
    swaymsg output "$name" mode "${width}x${height}@${hz}Hz" scale "$scale"
    out_scale[$name]=$scale
    out_width[$name]=$width
    out_height[$name]=$height
done <<< "$displays"

# Second pass: if an external monitor is present, put it at the top-left
# origin and place eDP-1 directly below it (using post-scale logical size)
external="$(awk -F'\t' '$1 != "eDP-1" { print $1; exit }' <<< "$displays")"
if [ -n "$external" ] && grep -qP '^eDP-1\t' <<< "$displays"; then
    ext_logical_h="$(awk -v h="${out_height[$external]}" -v s="${out_scale[$external]}" \
        'BEGIN { printf "%d", h / s }')"
    swaymsg output "$external" position 0 0
    swaymsg output eDP-1 position 0 "$ext_logical_h"
fi

i=1
while IFS=$'\t' read -r name identifier _; do
    swaymsg workspace "$i", move workspace to output \'"$identifier"\'
    swaybg -o "$name" -i "$wallpaper_file" -m fill >/dev/null 2>&1 &
    disown
    echo "$identifier" >> "$config_file"
    i=$((i+1))
done <<< "$displays"

printf "%s" "$(< "$config_file")"
