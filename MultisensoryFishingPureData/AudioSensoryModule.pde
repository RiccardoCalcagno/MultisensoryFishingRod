
enum ShakeDimention{
     NONE,
     LITTLE_ATTRACTING,
     LONG_ATTRACTING,
     STRONG_HOOKING,
     STRONG_NOT_HOOKING
}

class AudioSensoryModuleClass{
  private CallPureData pureData;
  private Long wheelPlayTime;
  private Long whipSoundPlayTime;
  private float longAttractingVolume;
  private boolean longAttracting;
  private Long lastTimeLongAttacktingUpdated;

 AudioSensoryModuleClass(){
    pureData = new CallPureData();
    wheelPlayTime = System.currentTimeMillis();
    whipSoundPlayTime = System.currentTimeMillis();
    lastTimeLongAttacktingUpdated = System.currentTimeMillis();
    longAttractingVolume = 0.0f;
    longAttracting = false;
  }
  // Once per gameLoop
  public void OnRodStatusReading(RodStatusData dataSnapshot){
    playWheelTickSound(dataSnapshot.speedOfWireRetrieving);
    playRodWhipSound(dataSnapshot.rawMotionData);
    playWireTensionSound(dataSnapshot.coefficentOfWireTension);

    //TODO: correct place for function call
    //float fishIntentionality = getFishIntentionality();
    //setSongIntensity(fishIntentionality);
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
    
    playLongAttractingSound();
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
  
  // event fired when the fish is touching the hook. I (Riccardo) change its movemnts in the way that 1 event of tasting the bait has at least 0.8 sec of distance between each others
  void OnFishTasteBait(){
    pureData.playAnySound(Sound.TASTE);
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
   audioSensoryModule.playLongAttractingSound();
   timer += 1;
   if (timer == 1) {
     audioSensoryModule.OnShakeOfRod(ShakeDimention.LONG_ATTRACTING);
   }
   if (timer == 400) {
     audioSensoryModule.OnShakeOfRod(ShakeDimention.NONE);
   }
   if (timer == 500) {
      audioSensoryModule.OnShakeOfRod(ShakeDimention.LITTLE_ATTRACTING);
    }
    if (timer == 600) {
      audioSensoryModule.OnShakeOfRod(ShakeDimention.STRONG_HOOKING);
    }
    if (timer == 700) {
      audioSensoryModule.OnShakeOfRod(ShakeDimention.STRONG_NOT_HOOKING);
    }
   /* if (timer % 30 == 0 && timer < 100) {
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
  if (timer % 100 == 0 && timer < 1000) {
    audioSensoryModule.setSongIntensity(random(0, 1));
  }
  if (timer == 1000) {
    audioSensoryModule.setSongIntensity(0);
  } */
}
