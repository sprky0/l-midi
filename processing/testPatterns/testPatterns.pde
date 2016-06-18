import processing.serial.*;

Serial arduinoPort;
int portNum = 6; // left USB
int delayTime = 1;
int a = 0;

void setup() {

	// could find this automatically by the expected key or something
	arduinoPort = new Serial(this, arduinoPort.list()[portNum], 115200);

	arduinoPort.write("00000000000000000000000000000000\n");
	delay(2000);

	frameRate(30);
	size(1024, 512);
	colorMode(RGB, 255, 255, 255, 255);

}

void allOn() {
	arduinoPort.write("11111111111111111111111111111111\n");
}

void bouncer() {
	for( int i = 0; i < 32; i++) {
		lightOn(32 - i);
		lightOn(i);
		delay(delayTime);
		lightOff(i);
		lightOff(32 - i);
		delay(delayTime);
	}
	delayTime+= 1;
}


void bouncer2() {
	delayTime = 100;
	for(int i = 0; i < 32; i++) {
		delay(delayTime);
		if (i + a % 2 == 0) {
			lightOff(i);
		} else {
			lightOn(i);
		}
		delay(delayTime);
		a++;
	}
}

void randomizer() {
	int which = (int) random(0,32);
	println(which);
	lightOn(which);
	delay(100);
	lightOff(which);
}

void draw() {
	// bouncer();
	// randomizer();
	// bouncer2();
	allOn();
}

void mouseClicked() {
	delayTime = 1;
}

void lightOn(int lightnum) {
	lightCmd(lightnum, "1");
}

void lightOff(int lightnum) {
	lightCmd(lightnum, "0");
}

void lightCmd (int lightnum, String cmdMode) {
	String cmd = "";
	for(int i = 0; i < lightnum; i++) {
		cmd += " ";
	}
	cmd += cmdMode + "\n";
	arduinoPort.write(cmd);
}
