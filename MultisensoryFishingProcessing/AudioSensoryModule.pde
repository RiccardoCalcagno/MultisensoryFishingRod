class AudioSensoryModule extends AbstSensoryOutModule{
  private CallPureData pureData;
  private float lastSpeed =0;
  private float precSongVolume;


  AudioSensoryModule(OutputModulesManager _outputModulesManager){
    super(_outputModulesManager);
    pureData = new CallPureData();
  }
  
  void ResetGame(){
    lastSpeed = 0;
    pureData.playWheelSound(0, 0f);
    precSongVolume = 0;
    pureData.playSong(0, 0, 0, 0);
    pureData.playWireTensionSound(0, 0, false);
  }
  
  
  // Once per gameLoop
  public void OnRodStatusReading(RodStatusData dataSnapshot){
    
    lastSpeed = lerp(dataSnapshot.speedOfWireRetrieving, lastSpeed, 0.7);
    
    
    float fishIntentionality = 0;
    //playWheelTickSound(lastSpeed);
    if(outputModulesManager.isFishHooked()){
      playWireTensionSound(dataSnapshot.coefficentOfWireTension);
      fishIntentionality = 0.8;
    }
    else{
      fishIntentionality = outputModulesManager.getFish().getIntentionality();
    }
    
    setSongIntensity(fishIntentionality);
  }

  private void playWheelTickSound(float speedOfWireRetrieving){
    
    float MAX_VOLUME = 300;
    
    println(speedOfWireRetrieving);
    //we want the pitch of the wheel sound to go from 2.0 to 4.0
    float wheelSoundSpeed = abs(speedOfWireRetrieving)*1.3;
    //System.out.println(wheelSoundSpeed);
    pureData.playWheelSound(wheelSoundSpeed, map(wheelSoundSpeed, 0, 1, MAX_VOLUME, MAX_VOLUME*0.80));
  }
  
  private void playWireTensionSound(float coefficientOfWireTension){
    if (coefficientOfWireTension < 0.2) {
      pureData.playWireTensionSound(0, 0, false);
      return;
    }
    //we want the pitch of the wheel sound to go from 2.0 to 4.0
    float wirePitch = 2.0f + (abs(coefficientOfWireTension)*2);
    pureData.playWireTensionSound(wirePitch, abs(coefficientOfWireTension)*2, true);
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
    pureData.playAnySound(Sound.LOST);
  }
  void OnFishCaught(){
    pureData.playAnySound(Sound.CAUGHT);
  }
  void OnWireEndedWithNoFish(){
    pureData.playAnySound(Sound.WIRE);
  }
}
