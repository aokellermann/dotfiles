#!/bin/bash

set -e

if [ -z "$@" ]; then
    displays="$(swaymsg -t get_outputs | jq -r '.[] | select(.active == true) | .make + " " + .model + " " + .serial')"
else
    displays=$@
fi

config_file="$HOME/.config/sway_win_extra"
rm -f "$config_file"

wallpaper_file="$HOME/images/wallpapers/cityscape_synthwave_moon_buildings_4k_hd_vaporwave.jpg"

i=1
echo "$displays" | while IFS= read -r d; do
    swaymsg workspace "$i", move workspace to output \'"$d"\'
    swaybg -o "$d" -i "$wallpaper_file" -m fill &
    echo "$d" >> "$config_file"
    i=$((i+1))
done

printf "%s" "$(< "$config_file")"
