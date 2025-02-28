#! /usr/bin/env bash

SAVE_PATH=$(xdg-user-dir PICTURES)/Screenshots/$(date +'Screenshot_from_%F_%T.png')
 grim -g "$(slurp -o)" $SAVE_PATH
 play $HOME/.config/hypr/hyprsounds/camera-shutter.ogg
notify-send -u normal "Screenshot saved" "\n$SAVE_PATH" -i $SAVE_PATH
