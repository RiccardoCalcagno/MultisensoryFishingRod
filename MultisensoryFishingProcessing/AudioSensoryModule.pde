class AudioSensoryModule extends AbstSensoryOutModule{
  private CallPureData pureData;
  private Long wheelPlayTime;
  private Long whipSoundPlayTime;


  AudioSensoryModule(OutputModulesManager outputModulesManager){
    super(outputModulesManager);

    pureData = new CallPureData();
    wheelPlayTime = System.currentTimeMillis();
    whipSoundPlayTime = System.currentTimeMillis();
  }

  // Once per gameLoop
  void OnRodStatusReading(RodStatusData dataSnapshot){
    //only play the wheel sound again if the last wheel sound is finished
    if (System.currentTimeMillis() > wheelPlayTime)  {
      float wheelSoundSpeed = abs(50 / dataSnapshot.speedOfWireRetrieving);
      pureData.playWheelSound(abs(dataSnapshot.speedOfWireRetrieving), 1.0f);
      wheelPlayTime = System.currentTimeMillis() + (long)wheelSoundSpeed;
    }
    
    // 0 means not in tension. if isFishHooked == true => coefficentOfWireTension = 0
    // max tension when the fish is pulling in the opposite direction of the wire and the speedOfWireRetrieving is equal to -1
    float coefficentOfWireTension = dataSnapshot.coefficentOfWireTension;; 
    
    // Check RawMotionData in SensoryInputModule script
    RawMotionData rawMotionData = dataSnapshot.rawMotionData;

  }
  
  // Asyncronous meningful events
  void OnShakeOfRod(ShakeDimention rodShakeType){
  }
  
  // event fired when the fish is touching the hook. I (Riccardo) change its movemnts in the way that 1 event of tasting the bait has at least 0.8 sec of distance between each others
  void OnFishTasteBait(){
    pureData.playAnySound(Sound.TASTE);
  }
  
  void OnFishHooked(){}
  
  void OnFishLost(){}
  void OnFishCaught(){}
  void OnWireEndedWithNoFish(){}
}
