# LMIDI

Keeping track of this for my own sanity so it's not 100% readable yet.  This is a project for a very particular installation which:

* plays back midi and audio side by side keeping them in sync
* relayes midi data as simple on / off messages via serial to an arduino
* reads serial data on an arduino and uses this to change pinstates
* socket server which accepts short commands over TCP to play / pause / shut down the system
* reads pinstates on the GPIO of a Raspberry PI, and then transmits then to java via a socket

and of course there is more hardware after that but it doesn't involve code so that's all that is in here

## Arduino Setup

Flash the EEPROM with the application in `arduino/serial2pin/serial2pin.ino`.  Use a MEGA board as we need a lot of pins.  Check source for pin routing.

## RaspberryPI Setup

Latest codebase into your home directory as user `pi` under directory l-midi.

Add autostart to launch java application when desktop is launched via `~/.config/lxsession/LXDE-pi/autostart`

```
@/bin/bash /home/pi/l-midi/scripts/lmidi-start.sh
```

^ Note that this file is slimmer than it starts, the above removes the menu, etc which we don't need.

Assuming GPIO18 for shutdown button, GPIO24 for playpause.

## Pitfalls, Todos

Note that on a MacBook Pro the USB port is 6 in the array of serial ports in java, and on the Pi it is 0.  Detect this automatically some day.
