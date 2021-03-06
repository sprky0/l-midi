import javax.sound.midi.*;
import processing.sound.*;

SoundFile audio;
Sequence sequence;
Sequencer sequencer;
long lastCheck = 0;

boolean pedalOn = false;


int noteCount = 128;
int noteState[] = {
	0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, // 32
	0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, // 64
	0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, // 96
	0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0 // 128
};
int noteVelocity[] = {
	0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, // 32
	0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, // 64
	0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, // 96
	0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0 // 128
}; // 256 notes

void setup() {

	frameRate(30);
	size(1024, 512);
	colorMode(RGB, 255, 255, 255, 255);

	audio = new SoundFile(this, "op48.mp3");

	try {

		// File midiFile = new File(dataPath("demo.mid"));
		//File midiFile = new File(dataPath("test.mid"));
		File midiFile = new File(dataPath("op48.mid"));
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
				System.out.println("MEL - type: " + type + " " + zip[0] + " " + zip[1] + " " + zip[2]);

				// note off or note interrupted by silent note
				if (type == 2 || (type == 1 && zip[2] == 0)) {
					// off / off equivalent
					// noteVelocity[zip[1]] = 0;
					noteState[zip[1]] = 0;
				}

				// note on, has velocity
				else if (type == 1 && zip[2] > 0) {
					// on @ velocity x y z
					noteVelocity[zip[1]] = zip[2];
					noteState[zip[1]] = 1;
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
					System.out.println("CEL - note on!");
				} else if (command == ShortMessage.NOTE_OFF) {
					System.out.println("CEL - note off!");
				} else {
					System.out.println("CEL - unknown: " + event.getData1() + " " + event.getData2());
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
		System.out.println("Listening to: " + sb.toString());

		Track[] tracks = sequence.getTracks();
		Track trk = sequence.createTrack();
		for (int i = 0; i < tracks.length; i++) { // Track track : tracks
			// grab the note data
			addNotesToTrack(tracks[i], trk);
			// mute this track so we don't get double sound
			sequencer.setTrackMute(i, true);
		}

		sequencer.setSequence(sequence);

		sequencer.start();
		audio.play();

	} catch (Exception e){

	}

}

void draw() {

	// fade state
	fill(0,0,0);
	rect(0,0,1024,512);

	for (int i = 0; i < noteCount; i++) {
		// System.out.println( notes[i] + " " + i);
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
	}

	// optionally deal with loop
	/*
	sequencer.stop();
	sequencer.close();
	*/

	if (millis() - lastCheck > 500) { // long lastCheck = 0;
		long seqPos = sequencer.getMicrosecondPosition();
		// long audPos = audio.getMicrosecondPosition();
		// todo: check audPos and make sure they're tracking together -- may need to rewrite or wrap SoundFile
		println(seqPos);
		lastCheck = millis();
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
