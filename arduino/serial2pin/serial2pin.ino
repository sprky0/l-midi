#define pinCount 32
int pins[] = {
	// notes 0 - 15
	 2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 45, 53, 51, 49, 47,
	// notes 16-31
	22, 24, 26, 28, 30, 32, 34, 36, 38, 40, 42, 44, 46, 48, 50, 52
};
int delayTime = 250;

void setup() {
	for (int curPin = 0; curPin < pinCount; curPin++) {
		pinMode(pins[curPin], OUTPUT);           // set pin to input
		digitalWrite(pins[curPin], HIGH);           // set pin to input
	}
}

void loop() {
	for (int curPin = 0; curPin < pinCount; curPin++) {
		digitalWrite(pins[curPin], LOW);       // turn on pullup resistors
		delay(delayTime * 2);
		digitalWrite(pins[curPin], HIGH);       // turn on pullup resistors
		delay(delayTime * 2);
	}
	delay(4000);
}
