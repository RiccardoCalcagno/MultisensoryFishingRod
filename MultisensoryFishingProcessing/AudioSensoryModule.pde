class AudioSensoryModule extends AbstSensoryOutModule{
  private CallPureData pureData;
  private Long wheelPlayTime;
  private Long whipSoundPlayTime;
  private float lastSpeed =0;
  private float precSongVolume;
  private float longAttractingVolume;
  private boolean longAttracting;
  private Long lastTimeLongAttacktingUpdated;


  AudioSensoryModule(OutputModulesManager _outputModulesManager){
    super(_outputModulesManager);
    pureData = new CallPureData();
    wheelPlayTime = System.currentTimeMillis();
    whipSoundPlayTime = System.currentTimeMillis();
    lastTimeLongAttacktingUpdated = System.currentTimeMillis();
    longAttractingVolume = 0.0f;
    longAttracting = false;
  }
  
  void ResetGame(){
    lastSpeed = 0;
    pureData.playWheelSound(0, 0f);
    precSongVolume = 0;
    pureData.playSong(0, 0, 0, 0);
  }
  
  
  // Once per gameLoop
  public void OnRodStatusReading(RodStatusData dataSnapshot){
    
    lastSpeed = lerp(dataSnapshot.speedOfWireRetrieving, lastSpeed, 0.7);
    
    
    float fishIntentionality = 0;
    playWheelTickSound(lastSpeed);
    if(outputModulesManager.isFishHooked() == true){
      playWireTensionSound(dataSnapshot.coefficentOfWireTension);
      fishIntentionality = 0.8;
    }
    else{
      fishIntentionality = outputModulesManager.getFish().getIntentionality();
    }
    
    setSongIntensity(fishIntentionality);
    
    playLongAttractingSound();
  }

  private void playWheelTickSound(float speedOfWireRetrieving){
    
    float MAX_VOLUME = 300;
    
    println(speedOfWireRetrieving);
    //we want the pitch of the wheel sound to go from 2.0 to 4.0
    float wheelSoundSpeed = abs(speedOfWireRetrieving)*1.3;
    //System.out.println(wheelSoundSpeed);
    pureData.playWheelSound(wheelSoundSpeed, map(wheelSoundSpeed, 0, 1, MAX_VOLUME, MAX_VOLUME*0.80));
  }

  private void playRodWhipSound(RawMotionData rawMotionData){
    if (rawMotionData == null) return;
    if (System.currentTimeMillis() <= whipSoundPlayTime) return;

    // Calculate the magnitude of the rod's motion
    float motionMagnitude = sqrt(pow(rawMotionData.acc_x, 2) + pow(rawMotionData.acc_y, 2) + pow(rawMotionData.acc_z, 2));
    // Normalize the magnitude to a suitable range for the pitch (you may need to adjust this)
    float whipSoundPitch = map(motionMagnitude, 0, 10, 1, 5);
    
    
    ShakeDimention shake = outputModulesManager.getCurrentShake();
    
    
    
    // Play the whip sound with the calculated pitch
    pureData.playPitchedWhip(whipSoundPitch, 1.0f);
    whipSoundPlayTime = System.currentTimeMillis() + 500; // Adjust the delay as needed
  }

  
  void playLongAttractingSound(){
    if (longAttracting){
      if (System.currentTimeMillis() - lastTimeLongAttacktingUpdated > 50){
        //Interpolate from longAttractingVolume to 0 in some time
        if (longAttractingVolume < 1.0f) {
          longAttractingVolume += 0.1f;
        } else {
          longAttractingVolume = 1.0f;
        }
        pureData.playTricklingSound(longAttractingVolume);
        lastTimeLongAttacktingUpdated = System.currentTimeMillis();
      }
    } else {
      if (System.currentTimeMillis() - lastTimeLongAttacktingUpdated > 50){
        //Interpolate from longAttractingVolume to 0 in some time
        if (longAttractingVolume > 0.0f) {
          longAttractingVolume -= 0.1f;
        } else {
          longAttractingVolume = 0.0f;
        }
        pureData.playTricklingSound(longAttractingVolume);
        lastTimeLongAttacktingUpdated = System.currentTimeMillis();
      }
    }
  }

  private void playWireTensionSound(float coefficentOfWireTension){
    //we want the pitch of the wheel sound to go from 2.0 to 4.0
    float wirePitch = 2.0f + (abs(coefficentOfWireTension)*2);
    pureData.playWireTensionSound(wirePitch, abs(coefficentOfWireTension)*2);
  }
 
  private void setSongIntensity(float fishIntentionality){
    
    
    float MAX_VOLUME = 0.5;
    if(outputModulesManager.isFishHooked() == true){
      MAX_VOLUME = 0.2;
    }
    
    precSongVolume = lerp(MAX_VOLUME, precSongVolume, 0.99);
 
    float val1 = 0;
    float val2 = 0;
    float val3 = 0;
    float val4 = 0;
    
    if (fishIntentionality < 0) {
      val1 = map(fishIntentionality, -0.3, 0, 0, precSongVolume);
    }
    else{
      val1 = precSongVolume;
    }
    if (fishIntentionality > 0) {
      val2 = map(fishIntentionality, 0, 0.8, 0, precSongVolume);
    }
    if(fishIntentionality > 0.25) {
      val3 = map(fishIntentionality, 0.25, 0.8, 0, precSongVolume);
    }
    if(fishIntentionality > 0.45) {
      val3 = map(fishIntentionality, 0.25, 0.8, 0, precSongVolume);
    }
    
    pureData.playSong(val3, val1, val4, val2);
  }

    // Asyncronous meningful events
    void OnShakeOfRod(ShakeDimention rodShakeType){
      switch(rodShakeType){
        case NONE:          
          longAttracting = false;
          break;
        case LITTLE_ATTRACTING:
          pureData.playSwashSound(1.2, 0.3f);
          longAttracting = false;
          break;
        case LONG_ATTRACTING:
            longAttracting = true;
          break;
        case STRONG_HOOKING:
          pureData.playSplashSound(2, 1.0f);
          longAttracting = false;
          break;
        case STRONG_NOT_HOOKING:
          pureData.playSplashSound(1, 0.75f);
          longAttracting = false;
          break;
      } 
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
