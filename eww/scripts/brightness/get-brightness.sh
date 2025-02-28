brightnessctl get 

socat -u UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock - | while read -r line; do
  brightnessctl get | awk -v max=$(brightnessctl max) '{print ($1 / max) * 100}'
done
