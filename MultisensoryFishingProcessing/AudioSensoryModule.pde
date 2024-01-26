class AudioSensoryModule extends AbstSensoryOutModule{
  private CallPureData pureData;
  private float lastSpeed =0;
  private float precSongVolume;
  private boolean endAnimation;


  AudioSensoryModule(OutputModulesManager _outputModulesManager){
    super(_outputModulesManager);
    pureData = new CallPureData();
    endAnimation = false;
  }
  
  void ResetGame(){
    lastSpeed = 0;
    pureData.playBubblesSound("NONE");
    pureData.playWheelSound(0, 0f);
    precSongVolume = 0;
    pureData.playSong(0, 0, 0, 0);
    pureData.playWireTensionSound(0, 0, false);
    endAnimation = false;
  }
  
  void OnEndGame(){
    pureData.playBubblesSound("NONE");
    pureData.playWireTensionSound(0, 0, false);
    pureData.playWheelSound(0, 0f);
    pureData.playSong(0, 0, 0, 0);
  }
  
  
  // Once per gameLoop
  public void OnRodStatusReading(RodStatusData dataSnapshot){
    
    float curSpeed = dataSnapshot.speedOfWireRetrieving;
    if(abs(dataSnapshot.speedOfWireRetrieving) < 0.05){
      curSpeed =0;
    }
    
    lastSpeed = lerp(curSpeed, lastSpeed, (abs(curSpeed) < 0.05)? 0.2 : 0.7);

    float fishIntentionality = 0;
    playWheelTickSound(lastSpeed);
    if(outputModulesManager.isFishHooked() && endAnimation == false){
      playWireTensionSound(dataSnapshot.coefficentOfWireTension);
      fishIntentionality = 0.8;
    }
    else{
      fishIntentionality = outputModulesManager.getFish().getIntentionality();
    }
    
    setSongIntensity(fishIntentionality);
  }

  private void playWheelTickSound(float speedOfWireRetrieving){
    float MAX_VOLUME = 100;
    //we want the pitch of the wheel sound to go from 2.0 to 4.0
    float wheelSoundSpeed = constrain(abs(speedOfWireRetrieving)*1.3, 0, 1);
    pureData.playWheelSound(wheelSoundSpeed, map(wheelSoundSpeed, 0, 1, MAX_VOLUME, MAX_VOLUME*0.80));
  }
  
  private void playWireTensionSound(float coefficientOfWireTension){
    
    float MAX_VOLUME = 5f;
    float volume = 0;
    float tremolo = 0;
  
    if (coefficientOfWireTension < 0.1) {
      volume = 0;
      tremolo = -1.29;
    }
    else{
      //we want the pitch of the wheel sound to go from 1.0 to 2.0
      volume = map(coefficientOfWireTension, 0.1, 1, 0, MAX_VOLUME);
      tremolo = map(coefficientOfWireTension, 0.1, 1, 0, 1);
    }
    pureData.playWireTensionSound(volume, coefficientOfWireTension, true);
  }
 
  private void setSongIntensity(float fishIntentionality){
    float MAX_VOLUME = 0.1;
    if(outputModulesManager.isFishHooked() == true){
      MAX_VOLUME = 0.01;
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
    
    if(outputModulesManager.isFishHooked() || endAnimation == true){
      return; 
    }
    switch(rodShakeType){
      case NONE: 
        pureData.playBubblesSound("NONE");
        break;
      case LITTLE_ATTRACTING:
        pureData.playBubblesSound("LITTLE_ATTRACTING");
        break;
      case LONG_ATTRACTING:
        pureData.playBubblesSound("LONG_ATTRACTING");
        break;
      case STRONG_HOOKING:
        pureData.playBubblesSound("STRONG_HOOKING");
        break;
      case STRONG_NOT_HOOKING:
        pureData.playBubblesSound("STRONG_NOT_HOOKING");
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
    endAnimation= true;
    pureData.playWireTensionSound(0, 0, false);
    pureData.playAnySound(Sound.LOST);
  }
  void OnFishCaught(){
    endAnimation = true;
    pureData.playWireTensionSound(0, 0, false);
    pureData.playAnySound(Sound.CAUGHT);
  }
  void OnWireEndedWithNoFish(){
    endAnimation = true;
    pureData.playWireTensionSound(0, 0, false);
    pureData.playAnySound(Sound.WIRE);
  }
}
