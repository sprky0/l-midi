import javax.sound.midi.*;

int notes[] = {
	0,0,0,0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,0,0,0,
	0,0,0,0,0,0
}; // 256 notes

void setup() {

	frameRate(60);
	size(512, 200);

	try {

		// File midiFile = new File(dataPath("demo.mid"));
		File midiFile = new File(dataPath("test.mid"));
		Sequencer sequencer = MidiSystem.getSequencer();

		sequencer.open();
		Sequence sequence = MidiSystem.getSequence(midiFile);
		sequencer.setSequence(sequence);

		MetaEventListener mel = new MetaEventListener() {
			@Override
			public void meta(MetaMessage meta) {
				final int type = meta.getType();
				byte[] zip = meta.getData();
				System.out.println("MEL - type: " + type + " " + zip[0] + " " + zip[1] + " " + zip[2]);
				// 0 = ???, 1 = note number, 2 = velocity ?
				if (type == 2) {
					notes[zip[1]] = 0;
				} else if (type == 1) {
					notes[zip[1]] = zip[2];
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
					System.out.println("CEL - unknown: " + command);
				}
			}
		};
		int[] listeningTo = sequencer.addControllerEventListener(cel, types);
		StringBuilder sb = new StringBuilder();
		for (int ii = 0; ii < listeningTo.length; ii++) {
				sb.append(ii);
				sb.append(", ");
		}
		System.out.println("Listenning to: " + sb.toString());

		Track[] tracks = sequence.getTracks();
		Track trk = sequence.createTrack();
		for (Track track : tracks) {
			addNotesToTrack(track, trk);
		}

		sequencer.setSequence(sequence);
		sequencer.start();

	} catch (Exception e){

	}

}

void draw() {

	for (int i = 0; i < notes.length; i++) {
		// System.out.println( notes[i] + " " + i);
		if (notes[i] > 0) {
			fill(255,  0,  0);
		} else {
			fill(  0,  0,  0);
		}
		rect(i * 4, 0, 4, 200);
	}
	// deal with loop
	/*
	sequencer.stop();
	sequencer.close();
	*/

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
