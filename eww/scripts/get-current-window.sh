hyprctl activewindow -j | jq -r 

socat -u UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock - | while read -r line; do
  hyprctl activewindow -j | jq -r '.class' 
done
