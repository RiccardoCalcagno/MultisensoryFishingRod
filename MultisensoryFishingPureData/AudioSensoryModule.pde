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
    //only play the wheel sound again if the last wheel sound is finished
    if (System.currentTimeMillis() > wheelPlayTime)  {
      //we want the pitch of the wheel sound to go from 2.0 to 2.2
      float wheelSoundSpeed = 2.0f + (abs(dataSnapshot.speedOfWireRetrieving)/5);
      //System.out.println(wheelSoundSpeed);
      pureData.playWheelSound(wheelSoundSpeed, 1.0f)
      ;
      long waitTime = (long)(33.3/abs(dataSnapshot.speedOfWireRetrieving));
      System.out.println(waitTime);
      wheelPlayTime = System.currentTimeMillis() + waitTime;
    }
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


class RodStatusData{
  float speedOfWireRetrieving;
}


void setup() {
  //FOR TESTING
  AudioSensoryModuleClass audioSensoryModule = new AudioSensoryModuleClass();
  RodStatusData rodStatusData = new RodStatusData();
  rodStatusData.speedOfWireRetrieving = -1;
  for (int i = 0; i < 200; i++) {
    audioSensoryModule.OnRodStatusReading(rodStatusData);
    delay(10);
  }
  rodStatusData.speedOfWireRetrieving = 0.1;
  for (int i = 0; i < 200; i++) {
    audioSensoryModule.OnRodStatusReading(rodStatusData);
    delay(10);
  }
}
