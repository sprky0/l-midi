#define pinCount 32

int pins[] = {
	// notes  0 - 15
	 2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 45, 53, 51, 49, 47,
	// notes 16 - 31
	22, 24, 26, 28, 30, 32, 34, 36, 38, 40, 42, 44, 46, 48, 50, 52
};

// serial communication
bool stateChanged = false;
String command;

// relay state
bool states[] = {
	// notes  0 - 15
	false, false, false, false, false, false, false, false,
	false, false, false, false, false, false, false, false,
	// notes 16 - 31
	false, false, false, false, false, false, false, false,
	false, false, false, false, false, false, false, false
};

void setup() {

	Serial.begin(115200);

	// we just need 32 bytes to store our shite
	// actually we don't even really need this at all, it's just the last state as a string
	command.reserve(32);

	for (int curPin = 0; curPin < pinCount; curPin++) {
		pinMode(pins[curPin], OUTPUT);           // set pin to input
		digitalWrite(pins[curPin], HIGH);           // set pin to input
	}
	delay(1000);

}

void loop() {
	// state has changed, send immediately
	if (stateChanged) {
		sendState();
		stateChanged = false;
	}
	// delay(10);
}

void sendState() {
	for (int curPin = 0; curPin < pinCount; curPin++) {
		digitalWrite(pins[curPin], states[curPin] ? LOW : HIGH);       // turn on pullup resistors
	}
}

void serialEvent() {
	while (Serial.available()) {
		// get the new byte:
		char inChar = (char)Serial.read();
		// add it to the inputString:
		command += inChar;
		// if the incoming character is a newline, set a flag
		// so the main loop can do something about it:
		if (inChar == '\n') {
			for(int i = 0; i < command.length(); i++) {
				Serial.print(command.charAt(i));
			}
			Serial.print('\n');
			Serial.print(command);
			stateChanged = true;
			// parse state
			command = "";
		}
	}
}
