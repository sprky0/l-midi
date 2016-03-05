#define pinStart 0
#define pinCount 54	// total pins
int delayTime = 10;

void setup() {
	for (int curPin = pinStart; curPin < pinStart + pinCount; curPin++) {
		pinMode(curPin, OUTPUT);           // set pin to input
		digitalWrite(curPin, HIGH);           // set pin to input
	}

}

void loop() {
	/*
	for (int curPin = pinStart; curPin < pinStart + pinCount; curPin++) {
		digitalWrite(curPin, LOW);       // turn on pullup resistors
		delay(delayTime * 2);
		digitalWrite(curPin, HIGH);       // turn on pullup resistors
		delay(delayTime * 2);
	}
	delay(4000);
	*/
}
