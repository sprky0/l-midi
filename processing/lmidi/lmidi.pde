import java.io.File;
import java.io.IOException;

import processing.net.*;

import javax.sound.sampled.AudioInputStream;
import javax.sound.sampled.AudioSystem;
import javax.sound.sampled.Clip;
import javax.sound.sampled.LineUnavailableException;
import javax.sound.sampled.UnsupportedAudioFileException;

import javax.sound.midi.*;

// import processing.io.*;
import processing.serial.*;

Server myServer;

Clip audio;
Sequence sequence;
Sequencer sequencer;
long lastCheck = 0;
// how far can the playback drift before we correct it?
long microsecondOffsetThreshold = 1000;

Serial arduinoPort;
int portNum = 0; // top left RaspberryPI USB port
// int portNum = 6; // left USB

// boolean debugEnabled = false; // send serial?
boolean ioEnabled = true; // deal with GPIO ?
boolean serialEnabled = true; // send serial?
boolean audioMuted = false; // mute audio?
boolean midiMuted = true; // mute midi?
boolean drawEnabled = false; // true; // visual representation

boolean sequencePlaying = false;

boolean pedalOn = false;

boolean mapOutOfBoundsNotesToEdge = true;

int noteTransposition = -50;//-32; // some base lowest note (note + this becomes our '0')
int postTranspositionLowest = 0;
int postTranspositionHighest = 32;

int noteCount = 128;
int noteState[] = {
	-1,-1,-1,-1,-1,-1,-1,-1, -1,-1,-1,-1,-1,-1,-1,-1, -1,-1,-1,-1,-1,-1,-1,-1, -1,-1,-1,-1,-1,-1,-1,-1, // 32
	-1,-1,-1,-1,-1,-1,-1,-1, -1,-1,-1,-1,-1,-1,-1,-1, -1,-1,-1,-1,-1,-1,-1,-1, -1,-1,-1,-1,-1,-1,-1,-1, // 64
	-1,-1,-1,-1,-1,-1,-1,-1, -1,-1,-1,-1,-1,-1,-1,-1, -1,-1,-1,-1,-1,-1,-1,-1, -1,-1,-1,-1,-1,-1,-1,-1, // 96
	-1,-1,-1,-1,-1,-1,-1,-1, -1,-1,-1,-1,-1,-1,-1,-1, -1,-1,-1,-1,-1,-1,-1,-1, -1,-1,-1,-1,-1,-1,-1,-1  // 127
};
int lastNoteState[] = {
	-1,-1,-1,-1,-1,-1,-1,-1, -1,-1,-1,-1,-1,-1,-1,-1, -1,-1,-1,-1,-1,-1,-1,-1, -1,-1,-1,-1,-1,-1,-1,-1, // 32
	-1,-1,-1,-1,-1,-1,-1,-1, -1,-1,-1,-1,-1,-1,-1,-1, -1,-1,-1,-1,-1,-1,-1,-1, -1,-1,-1,-1,-1,-1,-1,-1, // 64
	-1,-1,-1,-1,-1,-1,-1,-1, -1,-1,-1,-1,-1,-1,-1,-1, -1,-1,-1,-1,-1,-1,-1,-1, -1,-1,-1,-1,-1,-1,-1,-1, // 96
	-1,-1,-1,-1,-1,-1,-1,-1, -1,-1,-1,-1,-1,-1,-1,-1, -1,-1,-1,-1,-1,-1,-1,-1, -1,-1,-1,-1,-1,-1,-1,-1  // 127
};
int noteVelocity[] = {
	 0, 0, 0, 0, 0, 0, 0, 0,  0, 0, 0, 0, 0, 0, 0, 0,  0, 0, 0, 0, 0, 0, 0, 0,  0, 0, 0, 0, 0, 0, 0, 0, // 32
	 0, 0, 0, 0, 0, 0, 0, 0,  0, 0, 0, 0, 0, 0, 0, 0,  0, 0, 0, 0, 0, 0, 0, 0,  0, 0, 0, 0, 0, 0, 0, 0, // 64
	 0, 0, 0, 0, 0, 0, 0, 0,  0, 0, 0, 0, 0, 0, 0, 0,  0, 0, 0, 0, 0, 0, 0, 0,  0, 0, 0, 0, 0, 0, 0, 0, // 96
	 0, 0, 0, 0, 0, 0, 0, 0,  0, 0, 0, 0, 0, 0, 0, 0,  0, 0, 0, 0, 0, 0, 0, 0,  0, 0, 0, 0, 0, 0, 0, 0  // 128
}; // 256 notes



// sequences
int currentSequenceNumber = 0;
String sequenceList[] = {
	"run32-fast1",
	"deb_clai_format0"
};
int sequencePostDelayMS[] = {
	5000,
	5000
};
int sequenceTransposition[] = {
	-32,
	-50
};


void setup() {

	if (ioEnabled) {
		myServer = new Server(this, 7070);
	}

	if (serialEnabled) {

		// println(arduinoPort.list());
		// could find this automatically by the expected key or something
		// eg: String tester = "/dev/tty.usbmodem1411"; -- this doesn't work
		// how about sanitized a little? ... .trim() ? eh

		String[] ports = arduinoPort.list();

		// for(int i = 0; i < ports.length; i++) {
		// 	if (ports[i] == tester) {
		// 		portNum = i;
		// 		println("TIME TO GET " + i);
		// 	} else {
		// 		println("|" + ports[i] + "|");
		// 		println("|" + "/dev/tty.usbmodem1411" + "|");
		// 	}
		// }
		// arduinoPort.list()

		arduinoPort = new Serial(this, ports[portNum], 115200);

		delay(1000);
		arduinoPort.write("00000000000000000000000000000000\n");
		delay(1000);

	}

	frameRate(30);
	size(1024, 512);
	colorMode(RGB, 255, 255, 255, 255);

	// first set runs immediately!
	loadSet();
	startPlayback();

}

void allOff() {
	if (serialEnabled) {
		arduinoPort.write("00000000000000000000000000000000\n");
	}
}

void loadSet() {

	// adjust transposition to match current sequence
	noteTransposition = sequenceTransposition[currentSequenceNumber];

	String setToLoad = sequenceList[currentSequenceNumber];

	// load audio
	try {
		AudioInputStream audioIn;
		audioIn = AudioSystem.getAudioInputStream(new File(dataPath(setToLoad + ".wav")));
		audio = AudioSystem.getClip();
		audio.open(audioIn);
	} catch (UnsupportedAudioFileException e) {
		println("Issue loading audio - File type sucked");
	} catch (IOException e) {
		println("Issue loading audio - Couldn't get that file");
	} catch (LineUnavailableException e) {
		println("Issue loading audio - LineUnavailableException (???)");
	}

	// load midi
	try {

		File midiFile = new File(dataPath(setToLoad + ".mid"));
		sequencer = MidiSystem.getSequencer();

		sequencer.open();
		sequence = MidiSystem.getSequence(midiFile);
		sequencer.setSequence(sequence);

		MetaEventListener mel = new MetaEventListener() {
			@Override
			public void meta(MetaMessage meta) {
				final int type = meta.getType();
				byte[] zip = meta.getData();

				// 0 = ???, 1 = note number, 2 = velocity ?
				// //System.out.println("MEL - type: " + type + " " + zip[0] + " " + zip[1] + " " + zip[2]);

				// note off or note interrupted by silent note
				if (type == 2 || (type == 1 && zip[2] == 0)) {
					// off / off equivalent
					// noteVelocity[zip[1]] = 0;
					lastNoteState[zip[1]] = noteState[zip[1]];
					noteState[zip[1]] = 0;
				}

				// note on, has velocity
				else if (type == 1 && zip[2] > 0) {
					// on @ velocity x y z
					noteVelocity[zip[1]] = zip[2];
					lastNoteState[zip[1]] = noteState[zip[1]];
					noteState[zip[1]] = 1;
				}

				if (lastNoteState[zip[1]] != noteState[zip[1]]) {
					char noteValue = noteState[zip[1]] == 1 ? '1' : '0'; // convert to our char
					int sendNote = zip[1] + noteTransposition;
					String str = "";

					if (mapOutOfBoundsNotesToEdge && sendNote > postTranspositionHighest) {
						sendNote = postTranspositionHighest;
					}
					else if (mapOutOfBoundsNotesToEdge && sendNote > postTranspositionHighest) {
						sendNote = postTranspositionLowest;
					}

					for (int i = 0; i < postTranspositionHighest; i++) {
						if (i == sendNote) {
							str += noteValue;
						} else {
							str += ' ';
						}
					}
					str += '\n';

					if (serialEnabled) {
						arduinoPort.write(str);
					}

				}

			}
		};

		sequencer.addMetaEventListener(mel);

		int[] types = new int[128];
		for (int ii = 0; ii < 128; ii++) {
			types[ii] = ii;
		}
		ControllerEventListener cel = new ControllerEventListener() {
			@Override
			public void controlChange(ShortMessage event) {
				int command = event.getCommand();
				if (command == ShortMessage.NOTE_ON) {
					// //System.out.println("CEL - note on!");
				} else if (command == ShortMessage.NOTE_OFF) {
					// //System.out.println("CEL - note off!");
				} else {
					// //System.out.println("CEL - unknown: " + event.getData1() + " " + event.getData2());
					// keep track of the pedal state
					if (pedalOn == false && event.getData1() == 64 && event.getData2() == 127) {
						pedalOn = true;
					} else if (pedalOn == true) {
						pedalOn = false;
					}
				}
			}
		};
		int[] listeningTo = sequencer.addControllerEventListener(cel, types);
		StringBuilder sb = new StringBuilder();
		for (int ii = 0; ii < listeningTo.length; ii++) {
				sb.append(ii);
				sb.append(", ");
		}
		// //System.out.println("Listening to: " + sb.toString());

		Track[] tracks = sequence.getTracks();
		Track trk = sequence.createTrack();
		for (int i = 0; i < tracks.length; i++) { // Track track : tracks
			// grab the note data
			addNotesToTrack(tracks[i], trk);
			// mute this track so we don't get double sound
			if (midiMuted) {
				sequencer.setTrackMute(i, true);
			}
		}

		sequencer.setSequence(sequence);

	} catch (Exception e){

		//System.out.println("Failed to deal with midi");

	}

	// unlinking these two
	// startPlayback();

}

void mouseClicked() {

	println("MOUSE CLICKED -- STOP!!");
	stopPlayback();

	delay(1000);

}

void draw() {

	if (drawEnabled) {

		// fade state
		fill(0,0,0);
		rect(0,0,1024,512);

		for (int i = 0; i < noteCount; i++) {
			// //System.out.println( notes[i] + " " + i);
			if (noteVelocity[i] > 0) {
				if (noteState[i] == 1) {
					// note is on now
					fill(255,  i * 2,  i);
					rect(i * 8, 0, 8, 512);
				} else {
					// in this case the note is off but was formerly on
					// fill(100,  0,  0);
					// rect(i * 8, 0, 8, 512);
				}
			} else {
				// in this case the note was never on
				// fill(  0,  0,  0);
				// rect(i * 8, 0, 8, 512);
			}

			if ((i + noteTransposition) >= postTranspositionLowest && (i + noteTransposition) < postTranspositionLowest) {
				fill(  0, 255,   0);
				rect(i * 8, 0, 8, 512);
			}

		}

	}

	if (sequencePlaying) {
		fill(  0, 255,   0);
		rect(0, 0, 128, 512);
	} else {
		fill(255,  0,   0);
		rect(0, 0, 128, 512);
	}

	if (sequencePlaying && millis() - lastCheck > 500) { // long lastCheck = 0;

		long seqPos = sequencer.getMicrosecondPosition();
		long audPos = audio.getMicrosecondPosition();
		// todo: check audPos and make sure they're tracking together -- may need to rewrite or wrap SoundFile
		// //System.out.print(seqPos - audPos);
		// //System.out.println( " was the diff");

		if (Math.abs( seqPos - audPos ) > microsecondOffsetThreshold) {
			sequencer.setMicrosecondPosition( audPos );
		}

		// deal with sequence ending / moving to next

		if (audPos >= audio.getMicrosecondLength()) {

			stopPlayback();
			allOff();

			if (sequencePostDelayMS[currentSequenceNumber] > 0) {
				delay(sequencePostDelayMS[currentSequenceNumber]);
			}

			// autoadvance:
			nextSet();
			loadSet();
			startPlayback();

		}

		lastCheck = millis();

	}

	if (serialEnabled && arduinoPort.available() > 0)  {  // If data is available,
		String lastSerialRead = arduinoPort.readStringUntil('\n');         // read it and store it in val

		// lastSerialRead =
		/*
		switch(lastSerialRead) {

			default:
			//System.out.println("No clue: Artuino said");
			//System.out.println(lastSerialRead);
			break;

			case "thanks":
			//System.out.println("Arduino says: thanks / command ok!");
			break;

		}
		*/

	}

	if (ioEnabled) {
		// Get the next available client
		Client thisClient = myServer.available();
		// If the client is not null, and says something, display what it said
		if (thisClient !=null) {
			String whatClientSaid = thisClient.readString();
			if (whatClientSaid != null) {

				switch(whatClientSaid.trim()) {

					default:
					println(thisClient.ip() + " [" + whatClientSaid + "]");
					break;

					case "prev":
					if (sequencePlaying) {
						stopPlayback();
					}
					prevSet(); // maybe we should make a simplified "start playback" method
					loadSet();
					startPlayback();
					thisClient.write("thanks\n");
					println("prev received, sent thanks");
					break;

					case "next":
					if (sequencePlaying) {
						stopPlayback();
					}
					nextSet();
					loadSet();
					startPlayback();
					thisClient.write("thanks\n");
					println("next received, sent thanks");
					break;

					case "playpause":
					if (sequencePlaying) {
						stopPlayback();
					} else {
						startPlayback();
					}
					thisClient.write("thanks\n");
					println("playpause received, sent thanks");
					break;

					case "quit":
					thisClient.write("bye\n");
					thisClient.stop();
					break;

				}
			}
		}
	}
}

void stopPlayback() {

	if (sequencePlaying) {

		// stop audio
		audio.stop();
		// audio.close();

		// stop sequencer
		sequencer.stop();
		// sequencer.close();

		sequencePlaying = false;

	}

}

void startPlayback() {

	// rewind!
	sequencer.setMicrosecondPosition(0);
	audio.setMicrosecondPosition(0);

	// run audio and midi
	sequencer.start();
	if (!audioMuted) {
		audio.start();
	}
	sequencePlaying = true;

}

void prevSet() {
	currentSequenceNumber--;
	if (currentSequenceNumber < 0) {
		currentSequenceNumber = sequenceList.length - 1;
	}
}

void nextSet() {
	currentSequenceNumber++;
	if (currentSequenceNumber >= sequenceList.length) {
		currentSequenceNumber = 0;
	}
}

/**
 * Iterates the MIDI events of the first track and if they are a
 * NOTE_ON or NOTE_OFF message, adds them to the second track as a
 * Meta event.
 *
 * @note thank you to Andrew Thompson for this solution
 * @link http://stackoverflow.com/questions/27987400/how-to-get-note-on-off-messages-from-a-midi-sequence
 */
public static final void addNotesToTrack(Track track, Track trk) throws InvalidMidiDataException {
	for (int ii = 0; ii < track.size(); ii++) {
		MidiEvent me = track.get(ii);
		MidiMessage mm = me.getMessage();
		if (mm instanceof ShortMessage) {
			ShortMessage sm = (ShortMessage) mm;
			int command = sm.getCommand();
			int com = -1;
			if (command == ShortMessage.NOTE_ON) {
				com = 1;
			} else if (command == ShortMessage.NOTE_OFF) {
				com = 2;
			}
			if (com > 0) {
				byte[] b = sm.getMessage();
				int l = (b == null ? 0 : b.length);
				MetaMessage metaMessage = new MetaMessage(com, b, l);
				MidiEvent me2 = new MidiEvent(metaMessage, me.getTick());
				trk.add(me2);
			}
		}
	}
}

/*

GPIO notes from p5.org

import processing.io.*;

void setup() {
  GPIO.pinMode(4, GPIO.INPUT);

  // On the Raspberry Pi, GPIO 4 is pin 7 on the pin header,
  // located on the fourth row, above one of the ground pins
  // For this particular board one could also write:
  // GPIO.pinMode(RPI.PIN7, GPIO.INPUT);

  frameRate(0.5);
}

void draw() {
  // sense the input pin
  if (GPIO.digitalRead(4) == GPIO.HIGH) {
    fill(255);
  } else {
    fill(204);
  }
  stroke(255);
  ellipse(width/2, height/2, width*0.75, height*0.75);
}


*/
