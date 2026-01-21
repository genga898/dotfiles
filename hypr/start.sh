#!/usr/bin/env bash

# hyprpaper: wallpaper
hyprpaper&

# nm-applet: wireless networks
nm-applet --indicator&

#blueman-applet: bluetooth
blueman-applet &

#eww
eww open-many topbar notification_popup_window &

# swayosd-server: osd(on-screen-display)
swayosd-server &

# walker app laucner
vicinae server &

# eww:custom notification daemon
/usr/bin/notification-daemon &
