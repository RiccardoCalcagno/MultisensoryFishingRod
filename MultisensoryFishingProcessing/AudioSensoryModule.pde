class AudioSensoryModule extends AbstSensoryOutModule{
  AudioSensoryModule(OutputModulesManager outputModulesManager){
    super(outputModulesManager);
  }

  // Once per gameLoop
  void OnRodStatusReading(RodStatusData dataSnapshot){}
  
  // Asyncronous meningful events
  void OnShakeOfRod(ShakeDimention rodShakeType){
    switch (rodShakeType) {
      case NONE:
        break;
      case SUBTLE:
        break;
      case LITTLE_ATTRACTING:
        break;
      case LONG_ATTRACTING:
        break;
      case LITTLE_NOT_ATTRACTING:
        break;
      case STRONG_HOOKING:
        break;
      case STRONG_NOT_HOOKING:
        break;
      default:
        break;
    }
  }
  
  // event fired when the fish is touching the hook. I (Riccardo) change its movemnts in the way that 1 event of tasting the bait has at least 0.8 sec of distance between each others
  void OnFishTasteBait(){}
  
  void OnFishHooked(){}
  
  void OnFishLost(){}
  void OnFishCaught(){}
  void OnWireEndedWithNoFish(){}
}
