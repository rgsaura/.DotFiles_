#!/usr/bin/env sh
media=(
  script="$PLUGIN_DIR/media.sh"
  updates=on
  icon=󰎄
  icon.font="$FONT:Bold:18.0"
)

sketchybar --add item media center \
           --set media "${media[@]}" \
           --subscribe media media_change
