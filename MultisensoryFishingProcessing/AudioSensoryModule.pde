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
  public void OnRodStatusReading(RodStatusData dataSnapshot){
    playWheelSound(dataSnapshot.speedOfWireRetrieving);
    playRodWhipSound(dataSnapshot.rawMotionData);

    // 0 means not in tension. if isFishHooked == true => coefficentOfWireTension = 0
    // max tension when the fish is pulling in the opposite direction of the wire and the speedOfWireRetrieving is equal to -1
    float coefficentOfWireTension = dataSnapshot.coefficentOfWireTension;; 
    //TODO: give auditory feedback of the tension of the wire?
  }

  private void playWheelTickSound(float speedOfWireRetrieving){
    if (speedOfWireRetrieving == 0.0f) return;
    //only play the wheel sound again if the last wheel sound is finished
    if (System.currentTimeMillis() <= wheelPlayTime) return; 

    //we want the pitch of the wheel sound to go from 2.0 to 4.0
    float wheelSoundSpeed = 2.0f + (abs(speedOfWireRetrieving)*2);
    //System.out.println(wheelSoundSpeed);
    pureData.playWheelSound(wheelSoundSpeed, 0.5f);
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
    float whipSoundVolume = map(motionMagnitude, 0, 10, 0.5f, 1.0f);
    // Play the whip sound with the calculated pitch
    pureData.playPitchedWhip(whipSoundPitch, whipSoundVolume);
    whipSoundPlayTime = System.currentTimeMillis() + 500; // Adjust the delay as needed
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
