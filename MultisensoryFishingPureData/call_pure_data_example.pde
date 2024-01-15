import netP5.*;
import oscP5.*;

OscP5 oscP5;
NetAddress myRemoteLocation;

void setup() {
  playAnySound("sounds/break.wav");
  delay(500);
  playPitchedWhip(4.0);
  delay(500);
  playPitchedWhip(-4.0);
  delay(500);

  playTwoSongs(0.0, 0.5);
  delay(2000);
  float volume1 = 0.0;
  float volume2 = 0.5;

  for (int i = 0; i <= 5; i++) {
    playTwoSongs(volume1, volume2);
    volume1 += 0.1;
    volume2 -= 0.1;
    delay(25); // Wait for 25 milliseconds between each change
  }
  delay(5000);
  playTwoSongs(0.0, 0.0);
}

void draw() { 
}

void playPitchedWhip(Float pitch) {
  oscP5 = new OscP5(this, 12000);
  myRemoteLocation = new NetAddress("127.0.0.1", 3000);

  // Launch the Pd patch
  String pdPath = ".";
  String patchPath = "/play_pitched_whip.pd";
  launch(pdPath, patchPath);
  
  OscMessage myMessage = new OscMessage("/pitch");
  myMessage.add(pitch); /* add an int to the osc message */
  oscP5.send(myMessage, myRemoteLocation);
}

void playAnySound(String soundPath) {
  oscP5 = new OscP5(this, 12001);
  myRemoteLocation = new NetAddress("127.0.0.1", 3001);

  // Launch the Pd patch
  String pdPath = ".";
  String patchPath = "/play_sound.pd";
  launch(pdPath, patchPath);
  
  OscMessage myMessage = new OscMessage("/play");
  myMessage.add(soundPath); /* add an int to the osc message */
  oscP5.send(myMessage, myRemoteLocation);
}

void playTwoSongs(float firstSongVolume, float secondSongVolume) {
  oscP5 = new OscP5(this, 12002); // Changed port to 12002
  myRemoteLocation = new NetAddress("127.0.0.1", 3002); // Changed port to 3002

  OscMessage myMessage = new OscMessage("/values");
  myMessage.add(firstSongVolume); /* add the first value to the osc message */
  myMessage.add(secondSongVolume); /* add the second value to the osc message */
  oscP5.send(myMessage, myRemoteLocation);
}
