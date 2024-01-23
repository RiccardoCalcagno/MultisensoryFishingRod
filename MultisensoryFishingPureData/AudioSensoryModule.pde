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


class RodStatusData{
  float speedOfWireRetrieving;
  float coefficentOfWireTension;
  RawMotionData rawMotionData;
}


class RawMotionData{
   float acc_x;
   float acc_y;
   float acc_z;
   RawMotionData(float acc_x, float acc_y, float acc_z){
         this.acc_x = acc_x;
         this.acc_y = acc_y;
         this.acc_z = acc_z;
   }
   RawMotionData(){
   }
}

AudioSensoryModuleClass audioSensoryModule;
RodStatusData rodStatusData;

void setup() {
  //FOR TESTING
  audioSensoryModule = new AudioSensoryModuleClass();
  rodStatusData = new RodStatusData();
  rodStatusData.speedOfWireRetrieving = 0.2;
  rodStatusData.coefficentOfWireTension = 0.2;
}

int timer = 0;

void draw() {
   audioSensoryModule.OnRodStatusReading(rodStatusData);
   timer += 1;
   if (timer % 30 == 0 && timer < 100) {
    rodStatusData.speedOfWireRetrieving = random(-1, 1); 
    rodStatusData.coefficentOfWireTension = random(-1, 1); 
    rodStatusData.rawMotionData = new RawMotionData(random(-20f, 20f),random(-20f, 20f), random(-20f, 20f));
   }
  if (timer >= 100) {
    rodStatusData.speedOfWireRetrieving = 0;
    rodStatusData.coefficentOfWireTension = 0;
    rodStatusData.rawMotionData = null;
  }
  if (timer == 120) {
    audioSensoryModule.OnFishTasteBait();
  }
  if (timer == 150) {
    audioSensoryModule.OnFishHooked();
  }
  if (timer == 180) {
    audioSensoryModule.OnFishLost();
  }
  if (timer == 210) {
    audioSensoryModule.OnFishCaught();
  }
  if (timer == 240) {
    audioSensoryModule.OnWireEndedWithNoFish();
  }
}
