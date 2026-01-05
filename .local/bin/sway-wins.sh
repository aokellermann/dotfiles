#!/bin/bash

set -e

config_file="$HOME/.config/sway_win_extra"
rm -f "$config_file"

wallpaper_file="$HOME/images/wallpapers/cityscape_synthwave_moon_buildings_4k_hd_vaporwave.jpg"

# Get both output name (for swaybg) and identifier (for config)
displays="$(swaymsg -t get_outputs | jq -r '.[] | select(.active == true) | .name + "\t" + .make + " " + .model + " " + .serial')"

i=1
while IFS=$'\t' read -r name identifier; do
    swaymsg workspace "$i", move workspace to output \'"$identifier"\'
    swaybg -o "$name" -i "$wallpaper_file" -m fill >/dev/null 2>&1 &
    disown
    echo "$identifier" >> "$config_file"
    i=$((i+1))
done <<< "$displays"

printf "%s" "$(< "$config_file")"
