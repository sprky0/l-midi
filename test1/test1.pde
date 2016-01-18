import javax.sound.midi.*;

class MListener implements MetaEventListener {
  void meta(MetaMessage message) {
   
    System.out.println("type");
    System.out.println(message.getType());
    
    System.out.println("message");
    System.out.println(message.getMessage());
  }
}

class CEListener implements ControllerEventListener {
  void controlChange(ShortMessage message) {
    // System.out.println("shit c");
  }
}

void setup() {

  MListener mListener = new MListener();
  CEListener cListener = new CEListener();
  int[] controllersToTrack = {0};

  try {
    File midiFile = new File(dataPath("test.mid"));
    Sequencer sequencer = MidiSystem.getSequencer();
    

    sequencer.open();
    Sequence sequence = MidiSystem.getSequence(midiFile);
    sequencer.setSequence(sequence);

    boolean mListenerSuccess = sequencer.addMetaEventListener(mListener);
    int[] cListenerSuccess = sequencer.addControllerEventListener(cListener,controllersToTrack);

    System.out.println(mListenerSuccess);
    System.out.println(cListenerSuccess);

    sequencer.start();
  } catch(Exception e) {

  }
}

void loop() {

}