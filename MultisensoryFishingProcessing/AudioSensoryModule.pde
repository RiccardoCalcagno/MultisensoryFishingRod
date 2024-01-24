class AudioSensoryModule extends AbstSensoryOutModule{
  private CallPureData pureData;
  private Long wheelPlayTime;
  private Long whipSoundPlayTime;
  private float longAttracktingVolume;
  private boolean longAttracting;
  private Long lastTimeLongAttacktingUpdated;


  AudioSensoryModule(OutputModulesManager _outputModulesManager){
    super(_outputModulesManager);
    pureData = new CallPureData();
    wheelPlayTime = System.currentTimeMillis();
    whipSoundPlayTime = System.currentTimeMillis();
    lastTimeLongAttacktingUpdated = System.currentTimeMillis();
    longAttracktingVolume = 0.0f;
    longAttracting = false;
  }
  // Once per gameLoop
  public void OnRodStatusReading(RodStatusData dataSnapshot){
    playWheelTickSound(dataSnapshot.speedOfWireRetrieving);
    //playRodWhipSound(dataSnapshot.rawMotionData);
    playWireTensionSound(dataSnapshot.coefficentOfWireTension);

    float fishIntentionality = outputModulesManager.getFish().getIntentionality();
    setSongIntensity(fishIntentionality);
    
    playLongAttracktingSound();
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
    
    
    
    ShakeDimention shake = outputModulesManager.getCurrentShake();
    
    
    
    // Play the whip sound with the calculated pitch
    pureData.playPitchedWhip(whipSoundPitch, 1.0f);
    whipSoundPlayTime = System.currentTimeMillis() + 500; // Adjust the delay as needed
  }

  
  void playLongAttracktingSound(){
    if (longAttracting){
      if (System.currentTimeMillis() - lastTimeLongAttacktingUpdated > 50){
        //Interpolate from longAttracktingVolume to 0 in some time
        if (longAttracktingVolume < 1.0f) {
          longAttracktingVolume += 0.1f;
        } else {
          longAttracktingVolume = 1.0f;
        }
        pureData.playTricklingSound(longAttracktingVolume);
        lastTimeLongAttacktingUpdated = System.currentTimeMillis();
      }
    } else {
      if (System.currentTimeMillis() - lastTimeLongAttacktingUpdated > 50){
        //Interpolate from longAttracktingVolume to 0 in some time
        if (longAttracktingVolume > 0.0f) {
          longAttracktingVolume -= 0.1f;
        } else {
          longAttracktingVolume = 0.0f;
        }
        pureData.playTricklingSound(longAttracktingVolume);
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
      switch(rodShakeType){
        case NONE:          
          longAttracting = false;
          break;
        case LITTLE_ATTRACTING:
          pureData.playPitchedSwash(1.2, 0.3f);
          longAttracting = false;
          break;
        case LONG_ATTRACTING:
            longAttracting = true;
          break;
        case STRONG_HOOKING:
          pureData.playPitchedSplash(2, 1.0f);
          longAttracting = false;
          break;
        case STRONG_NOT_HOOKING:
          pureData.playPitchedSplash(1, 0.75f);
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
