#!/bin/bash
sketchybar --add item weather right                            \
           --set weather script="$PLUGIN_DIR/weather.sh"       \
                         update_freq=600                       \
                         label.font="$FONT:Bold:14.0"          \
#!/bin/bash
weather=(
  script="$PLUGIN_DIR/weather.sh"
  update_freq=600
  label.font="$FONT:Bold:14.0"
)

sketchybar --add item weather right      \
           --set weather "${weather[@]}" \
