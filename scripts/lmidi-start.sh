#!/bin/bash
su pi
cd /home/pi/l-midi/processing
COUNTER=0
while [ 1 ]; do
   echo Run $COUNTER
	 DISPLAY=:0 processing-java --sketch=lmidi --present
   let COUNTER=COUNTER+1
done
