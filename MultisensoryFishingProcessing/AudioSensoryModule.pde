class AudioSensoryModule extends AbstSensoryOutModule{
  private CallPureData pureData;

  AudioSensoryModule(OutputModulesManager outputModulesManager){
    super(outputModulesManager);

    pureData = new CallPureData();
  }

  // Once per gameLoop
  void OnRodStatusReading(RodStatusData dataSnapshot){}
  
  // Asyncronous meningful events
  void OnShakeOfRod(ShakeDimention rodShakeType){
    switch (rodShakeType) {
      case NONE:
        break;
      case SUBTLE:
        pureData.playPitchedWhip(0.5f);
        pureData.playPitchedWhip(-0.5f);
        break;
      case LITTLE_ATTRACTING:
        pureData.playPitchedWhip(1.0f);
        pureData.playPitchedWhip(-1.0f);
        break;
      case LONG_ATTRACTING:
        pureData.playPitchedWhip(2.0f);
        pureData.playPitchedWhip(-2.0f);
        break;
      case LITTLE_NOT_ATTRACTING:
        pureData.playPitchedWhip(-2.0f);
        pureData.playPitchedWhip(2.0f);
        break;
      case STRONG_HOOKING:      
        pureData.playPitchedWhip(4.0f);
        break;
      case STRONG_NOT_HOOKING:
        pureData.playPitchedWhip(-4.0f);
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
