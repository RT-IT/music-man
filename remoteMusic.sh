#!/bin/bash

settingsFile="/home/pi/musicManPlayMode.txt"
source $settingsFile

echo 'musicManPlayMode="remote"' > $settingsFile

sleep 3s
killall vlc
cvlc https://radio.racetrackpitstop.co.uk/stream.ogg &
