wpctl get-volume @DEFAULT_SINK@

socat -u UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock - | while read -r line; do
  wpctl get-volume @DEFAULT_SINK@ | awk '{print $2 * 100}'
done
