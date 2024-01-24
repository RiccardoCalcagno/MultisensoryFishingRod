class AudioSensoryModuleClass{
  private CallPureData pureData;
  private Long wheelPlayTime;
  private Long whipSoundPlayTime;


  AudioSensoryModuleClass(){
    pureData = new CallPureData();
    wheelPlayTime = System.currentTimeMillis();
    whipSoundPlayTime = System.currentTimeMillis();
  }
  // Once per gameLoop
  public void OnRodStatusReading(RodStatusData dataSnapshot){
    playWheelTickSound(dataSnapshot.speedOfWireRetrieving);
    playRodWhipSound(dataSnapshot.rawMotionData);
    playWireTensionSound(dataSnapshot.coefficentOfWireTension);

    //TODO: correct place for function call
    //float fishIntentionality = getFishIntentionality();
    //setSongIntensity(fishIntentionality);
  }

  private void playWheelTickSound(float speedOfWireRetrieving){
    if (speedOfWireRetrieving == 0.0f) return;
    //only play the wheel sound again if the last wheel sound is finished
    if (System.currentTimeMillis() <= wheelPlayTime) return; 

    //we want the pitch of the wheel sound to go from 2.0 to 4.0
    float wheelSoundSpeed = 2.0f + (abs(speedOfWireRetrieving)*2);
    //System.out.println(wheelSoundSpeed);
    pureData.playWheelSound(wheelSoundSpeed, 1.0f);
    long waitTime = (long)(50/abs(speedOfWireRetrieving));
    wheelPlayTime = System.currentTimeMillis() + waitTime;
  }

  private void playRodWhipSound(RawMotionData rawMotionData){
    if (rawMotionData == null) return;
    if (System.currentTimeMillis() <= whipSoundPlayTime) return;

    // Calculate the magnitude of the rod's motion
    float motionMagnitude = sqrt(pow(rawMotionData.acc_x, 2) + pow(rawMotionData.acc_y, 2) + pow(rawMotionData.acc_z, 2));
    // Normalize the magnitude to a suitable range for the pitch (you may need to adjust this)
    float whipSoundPitch = map(motionMagnitude, 0, 10, 1, 5);
    // Play the whip sound with the calculated pitch
    pureData.playPitchedWhip(whipSoundPitch, 1.0f);
    whipSoundPlayTime = System.currentTimeMillis() + 500; // Adjust the delay as needed
  }

  private void playWireTensionSound(float coefficentOfWireTension){
    //we want the pitch of the wheel sound to go from 2.0 to 4.0
    float wirePitch = 2.0f + (abs(coefficentOfWireTension)*2);
    pureData.playWireTensionSound(wirePitch, abs(coefficentOfWireTension)*2);
  }
 
  private void setSongIntensity(float fishIntentionality){
    if (fishIntentionality == 0) {
      pureData.playSong(0, 0, 0, 0);
    } else if (fishIntentionality < 0.25f) { 
      pureData.playSong(0, 1, 0, 0);
    } else if (fishIntentionality < 0.5f) {
      pureData.playSong(0, 1, 1, 0);
    } else if (fishIntentionality < 0.75f) {
      pureData.playSong(1, 1, 1, 0);
    } else {
      pureData.playSong(1, 1, 1, 1);
    }
  }

  // Asyncronous meningful events
  void OnShakeOfRod(ShakeDimention rodShakeType){
    //TODO: playPitchedWhip better here?
  }
  // event fired when the fish is touching the hook. I (Riccardo) change its movemnts in the way that 1 event of tasting the bait has at least 0.8 sec of distance between each others
  void OnFishTasteBait(){
    pureData.playAnySound(Sound.TASTE);
  }
  
  void OnFishHooked(){
    pureData.playAnySound(Sound.HOOKED);
  }
  
  void OnFishLost(){
    pureData.playAnySound(Sound.LOST);
    }
  void OnFishCaught(){
    pureData.playAnySound(Sound.CAUGHT);
    }
  void OnWireEndedWithNoFish(){
    pureData.playAnySound(Sound.WIRE);
    }
  }
