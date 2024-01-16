import netP5.*;
import oscP5.*;
import java.util.Map;
import java.util.HashMap;

public enum Sound {
  BREAK,
  CAUGHT,
  HOOKED,
  LOST,
  TASTE,
  BITE,
  WIRE
}

public class CallPureData {
  OscP5 oscP5;
  NetAddress whipPort;
  NetAddress anySoundPort;
  NetAddress twoSongsPort;

  final String SKETCH_PATH_PITCHED_WHIP = "/play_pitched_whip.pd";
  final String SKETCH_PATH_PLAY_SOUND = "/play_sound.pd";
  final String SKETCH_PATH_TWO_SONGS = "/play_two_songs.pd";
  final String PD_PATH = ".";
  final HashMap SOUND_PATHS;

  public CallPureData() {
      oscP5 = new OscP5(this, 12000);
      whipPort = new NetAddress("127.0.0.1", 3000);
      anySoundPort = new NetAddress("127.0.0.1", 3001);
      twoSongsPort = new NetAddress("127.0.0.1", 3002);

      SOUND_PATHS = new HashMap<>();
      SOUND_PATHS.put(Sound.BREAK, "sounds/break.wav");
      SOUND_PATHS.put(Sound.CAUGHT, "sounds/fish_caught.wav");
      SOUND_PATHS.put(Sound.HOOKED, "sounds/fish_hooked.wav");
      SOUND_PATHS.put(Sound.LOST, "sounds/fish_lost.wav");
      SOUND_PATHS.put(Sound.TASTE, "sounds/taste.wav");
      SOUND_PATHS.put(Sound.BITE, "sounds/bite.wav");
      SOUND_PATHS.put(Sound.WIRE, "sounds/wire_ended.wav");
    }

  void test() {
    playAnySound(Sound.BREAK);
    delay(500);    
    playPitchedWhip(1.0, 1.0);
    delay(500);
    for (int i = 0; i <= 5; i++) {
    playPitchedWhip(4.0, 0.1);
      delay(250);
      playPitchedWhip(-4.0, 0.1);
      delay(250);
    }
    playPitchedWhip(4.0, 1.0);
    delay(500);

    //playTwoSongs(0.0, 0.5);
    //delay(2000);
    //float volume1 = 0.0;
    //float volume2 = 0.5;
//
    //for (int i = 0; i <= 5; i++) {
    //  playTwoSongs(volume1, volume2);
    //  volume1 += 0.1;
    //  volume2 -= 0.1;
    //  delay(25);
    //}
    //delay(5000);
    //playTwoSongs(0.0, 0.0);
  }


  public void playPitchedWhip(float pitch, float volume) {
    // Launch the Pd patch
    String pdPath = ".";
    launch(pdPath, SKETCH_PATH_PITCHED_WHIP);
    
    OscMessage myMessage = new OscMessage("/pitch");
    myMessage.add(pitch);
    myMessage.add(volume);
    oscP5.send(myMessage, whipPort);
  }

  public void playAnySound(Sound sound) {
    String soundPath = (String)SOUND_PATHS.get(sound);
    // Launch the Pd patch
    launch(PD_PATH, SKETCH_PATH_PLAY_SOUND);
    
    OscMessage myMessage = new OscMessage("/play");
    myMessage.add(soundPath);
    oscP5.send(myMessage, anySoundPort);
  }

  public void playTwoSongs(float firstSongVolume, float secondSongVolume) {
    launch(PD_PATH, SKETCH_PATH_TWO_SONGS);
    OscMessage myMessage = new OscMessage("/values");
    myMessage.add(firstSongVolume);
    myMessage.add(secondSongVolume);
    oscP5.send(myMessage, twoSongsPort);
  }
}

//void setup() {
//  CallPureData cpd = new CallPureData();
//  cpd.test();
//}
//
//void draw() { 
//}
