#!/usr/bin/env bash

# hyprpaper: wallpaper
hyprpaper&

# nm-applet: wireless networks
nm-applet --indicator&

#blueman-applet: bluetooth
blueman-applet &

#eww: topbar
eww daemon&
eww open topbar &
eww open notification_popup_window &

# swayosd-server: osd(on-screen-display)
swayosd-server &

# walker app laucner
walker --gapplication-service &

# eww:custom notification daemon
/usr/bin/notification-daemon &
