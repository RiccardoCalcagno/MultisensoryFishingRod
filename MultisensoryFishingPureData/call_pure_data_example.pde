import netP5.*;
import oscP5.*;

OscP5 oscP5;
NetAddress myRemoteLocation;

void setup() {
  playAnySound("sounds/break.wav");
  delay(1000);
  playPitchedWhip(4.0);
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
