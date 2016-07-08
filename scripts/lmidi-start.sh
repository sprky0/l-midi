#!/bin/bash
cd /home/pi/l-midi/processing
COUNTER=0
while [ 1 ]; do
    echo Run $COUNTER
    DISPLAY=:0 processing-java --sketch=lmidi --present > /tmp/lmidi.log 2>&1
    let COUNTER=COUNTER+1
done
