#!/bin/python

import RPi.GPIO as GPIO
import time
import os
import socket
import sys

# Our function on what to do when the button is pressed
def Shutdown(channel):
    os.system("sudo shutdown -h now")

def SendMessageToP5(message):
    try:
        response = 'thanks'
        # Open TCP/IP socket
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        # Connect the socket to the port where the server is listening
        server_address = ('localhost', 7070)
        print >>sys.stderr, 'connecting to %s port %s' % server_address
        sock.connect(server_address)
        # Send data
        # message = 'playpause'
        print >>sys.stderr, 'sending "%s"' % message
        sock.sendall(message)

        # Look for the response
        amount_received = 0
        # amount_expected = len(response)

        while amount_received < amount_expected:
            data = sock.recv(1024)
            amount_received += len(data)
            print >>sys.stderr, 'received "%s"' % data

    finally:
        print >>sys.stderr, 'closing socket'
        sock.close()

def PlayPause(channel):
    SendMessageToP5('playpause');

def NextSequence(channel):
    SendMessageToP5('prev');

def PrevSequence(channel):
    SendMessageToP5('next');

GPIO.setmode(GPIO.BCM)
GPIO.setup(18, GPIO.IN, pull_up_down = GPIO.PUD_UP)
GPIO.setup(24, GPIO.IN, pull_up_down = GPIO.PUD_UP)
GPIO.add_event_detect(18, GPIO.FALLING, callback = Shutdown, bouncetime = 2000)
GPIO.add_event_detect(24, GPIO.FALLING, callback = PlayPause, bouncetime = 2000)

# Now wait!
while 1:
    time.sleep(1)
