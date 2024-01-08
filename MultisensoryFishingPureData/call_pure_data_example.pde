import netP5.*;
import oscP5.*;

OscP5 oscP5;
NetAddress myRemoteLocation;

void setup() {
  oscP5 = new OscP5(this, 12000);
  myRemoteLocation = new NetAddress("127.0.0.1", 3000);

  // Launch the Pd patch
  String pdPath = ".";
  String patchPath = "/play_pitched_whip.pd";
  launch(pdPath, patchPath);
  
  OscMessage myMessage = new OscMessage("/pitch");
  myMessage.add(4.0); /* add an int to the osc message */
  oscP5.send(myMessage, myRemoteLocation);
}

void draw() { 
}
