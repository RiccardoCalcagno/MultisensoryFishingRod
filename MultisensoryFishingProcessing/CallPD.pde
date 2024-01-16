import netP5.*;
import oscP5.*;

public class CallPureData {
  OscP5 oscP5;
  NetAddress whipPort;
  NetAddress anySoundPort;
  NetAddress twoSongsPort;

  public CallPureData() {
      oscP5 = new OscP5(this, 12000);
      whipPort = new NetAddress("127.0.0.1", 3000);
      anySoundPort = new NetAddress("127.0.0.1", 3001);
      twoSongsPort = new NetAddress("127.0.0.1", 3002);
    }

  void test() {
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
      delay(25);
    }
    delay(5000);
    playTwoSongs(0.0, 0.0);
  }


  public void playPitchedWhip(Float pitch) {
    // Launch the Pd patch
    String pdPath = ".";
    String patchPath = "/play_pitched_whip.pd";
    launch(pdPath, patchPath);
    
    OscMessage myMessage = new OscMessage("/pitch");
    myMessage.add(pitch);
    oscP5.send(myMessage, whipPort);
  }

  public void playAnySound(String soundPath) {
    // Launch the Pd patch
    String pdPath = ".";
    String patchPath = "/play_sound.pd";
    launch(pdPath, patchPath);
    
    OscMessage myMessage = new OscMessage("/play");
    myMessage.add(soundPath);
    oscP5.send(myMessage, anySoundPort);
  }

  public void playTwoSongs(float firstSongVolume, float secondSongVolume) {
    whipPort = new NetAddress("127.0.0.1", 3002);

    OscMessage myMessage = new OscMessage("/values");
    myMessage.add(firstSongVolume);
    myMessage.add(secondSongVolume);
    oscP5.send(myMessage, twoSongsPort);
  }
}

/*
void setup() {
  CallPureData cpd = new CallPureData();
  cpd.test();
}

void draw() { 
}*/
