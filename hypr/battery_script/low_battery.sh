# /usr/bin/env bash

while true
do
	battery=$(cat /sys/class/power_supply/BAT0/capacity)
	charging=$(cat /sys/class/power_supply/BAT0/status)
	if [ "$battery" -le "20" ] && [ "$charging" != "Charging" ]; then
		notify-send -u critical "Low Battery" "${battery}% charge left" -i ~/.config/hypr/hyprpaper_images/battery-low.svg
		play $HOME/.config/hypr/hyprsounds/battery-low.ogg
		sleep 1200
	else
		sleep 120
	fi
done
