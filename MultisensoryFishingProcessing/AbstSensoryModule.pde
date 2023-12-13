interface PublicFish{
  float fishWidth = 500, fishHeight = 131; 
  // return a vector 3 of the position of the fish in the acquarium
  PVector getPos();
  
  // Fish intentionality is a coefficent from 0 to 1 that tell how much willing is the fish to bite the hook... 0 => random movement, 1 => strait movement to the hook. 
  float getIntentionality();
  
  PVector getFishRotation();
}


interface OutputModulesManager{
  // true <=> the player is in the second part of the session (retreiving the hooked fish)
  boolean isFishHooked();
  
  int getSizeOfAcquarium();
  
  // Use it if you need to have some information about the fish
  PublicFish getFish();
}

abstract class AbstSensoryOutModule{
  
  OutputModulesManager outputModulesManager;
  AbstSensoryOutModule(OutputModulesManager _outputModulesManager){
    outputModulesManager = _outputModulesManager;
  }
  
  // Once per gameLoop
  void OnRodStatusReading(RodStatusData dataSnapshot){}
  
  // Asyncronous meningful events
  void OnShakeOfRod(ShakeDimention rodShakeType){}
  
  // event fired when the fish is touching the hook. I (Riccardo) change its movemnts in the way that 1 event of tasting the bait has at least 0.8 sec of distance between each others
  void OnFishTasteBait(){}
  
  
  void OnFishHooked(){}
  
  void OnFishLost(){}
  
  void OnFishCaught(){}
  
  void OnWireEndedWithNoFish(){}
}

enum ShakeDimention{
     NONE,
     SUBTLE,
     LITTLE_ATTRACTING,
     LONG_ATTRACTING,
     LITTLE_NOT_ATTRACTING,
     STRONG_HOOKING,
     STRONG_NOT_HOOKING
}

class RodStatusData{
  
  // from -1 to 1. Normalized
  // negative speed for retreiving the wire, positive velocities for relising wire.
  float speedOfWireRetrieving;
  
  // 0 means not in tension. if isFishHooked == true => coefficentOfWireTension = 0
  // max tension when the fish is pulling in the opposite direction of the wire and the speedOfWireRetrieving is equal to -1
  float coefficentOfWireTension; 
  
  // Check RawMotionData in SensoryInputModule script
  RawMotionData rawMotionData;
}







/*
     ---------------------    Concretizations of AbstSensoryOutModule      -------------------------
     
     TODO, divided tasks, implemented in other file-scripts
      
    !!!!!!!!  Make use of the SerializationUtility static class and its methods to properly serialize the data to forward !!!!!!!!!!
*/
