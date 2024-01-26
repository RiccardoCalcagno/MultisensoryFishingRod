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
  NetAddress wheelPort;
  NetAddress stringPort;
  NetAddress bubblesPort;
  HashMap<Sound, String> SOUND_PATHS;

  public CallPureData() {
    oscP5 = new OscP5(this, 12000);
    whipPort = new NetAddress("127.0.0.1", 3000);
    anySoundPort = new NetAddress("127.0.0.1", 3001);
    twoSongsPort = new NetAddress("127.0.0.1", 3002);
    wheelPort = new NetAddress("127.0.0.1", 3003);
    stringPort = new NetAddress("127.0.0.1", 3004);
    bubblesPort = new NetAddress("127.0.0.1", 3005);

    SOUND_PATHS = new HashMap<Sound, String>();
    SOUND_PATHS.put(Sound.BREAK, "sounds/break.wav");
    SOUND_PATHS.put(Sound.CAUGHT, "sounds/fish_caught.wav");
    SOUND_PATHS.put(Sound.HOOKED, "sounds/fish_hooked.wav");
    SOUND_PATHS.put(Sound.LOST, "sounds/fish_lost.wav");
    SOUND_PATHS.put(Sound.TASTE, "sounds/taste.wav");
    SOUND_PATHS.put(Sound.BITE, "sounds/bite.wav");
    SOUND_PATHS.put(Sound.WIRE, "sounds/wire_ended.wav");
  }

  public void playPitchedWhip(float pitch, float volume) {
    OscMessage myMessage = new OscMessage("/pitch");
    myMessage.add(pitch);
    myMessage.add(volume);
    oscP5.send(myMessage, whipPort);
  }

  public void playWheelSound(float pitch, float volume) {
    OscMessage myMessage = new OscMessage("/wheel");
    myMessage.add(pitch);
    myMessage.add(volume);
    oscP5.send(myMessage, wheelPort);
  }

  public void playWireTensionSound(float volume, float tremolo, boolean play) {
    OscMessage myMessage = new OscMessage("/wire");
    myMessage.add(volume);
    myMessage.add(tremolo);
    myMessage.add(play ? 1 : 0);
    oscP5.send(myMessage, stringPort);
  }
  
  public void playBubblesSound(String typeOfShake) {
    OscMessage myMessage = new OscMessage("/bubbles");
    myMessage.add(typeOfShake);
    oscP5.send(myMessage, bubblesPort);
  }

  public void playAnySound(Sound sound) {
    OscMessage myMessage = new OscMessage("/play");
    myMessage.add(SOUND_PATHS.get(sound));
    oscP5.send(myMessage, anySoundPort);
  }

  public void playSong(float fluteVolume, float bassVolume, float guitarVolume, float drumsVolume) {
    OscMessage myMessage = new OscMessage("/values");
    myMessage.add(fluteVolume);
    myMessage.add(bassVolume);
    myMessage.add(guitarVolume);
    myMessage.add(drumsVolume);
    oscP5.send(myMessage, twoSongsPort);
  }
}
