interface InputModuleManager{

  // arrivi il tipo appena riconosciuto e quando non è più riconosciuto mandare un NONE oppure
  //il nuovo tipo riconosciuto (asincronamente, senza ripetizioni)
  void OnShakeEvent(ShakeDimention type);
  
  // speedOfWireRetrieving is from -1 to 1. Normalized. negative speed for retreiving the wire, positive velocities for relising wire.
  void OnWeelActivated(float speedOfWireRetrieving);
  
  // Costantemente
  void OnRawMotionDetected(RawMotionData data);
}

// TODO
// Manuel definirà quelle che possono essere le feature più esplicative per descrivere il movimento come velocities and accellerations.
// it is usefull, for instance, for the PureData to add sounds for the rod that is swinging
// NORMALIZZATI
class RawMotionData{
   float speed;
   float accelleration;
}

class SensoryInputModule{
  
  // Make use of the SerializationUtility static class and its methods to properly serialize the data to forward
  
  InputModuleManager inputModuleManager;
  
  // use inputModuleManager to notify the game with all the data comming from the rod
  SensoryInputModule(InputModuleManager _inputModuleManager){
    inputModuleManager = _inputModuleManager;
  }
  
}








class DebugSensoryInputModule extends SensoryInputModule{
  
  // Repetidly press one number between 1 an 7 (correspondent to the values of ShakeDimention) to trigger a burst of that kind of shake for all the time of the frequent digit
  HashMap<Integer, Boolean> keysPressed = new HashMap<Integer, Boolean>();

  boolean prevWasShake = false;
  //int lastPress = 0;
  //char lastChar = ' ';
  // use inputModuleManager to notify the game with all the data comming from the rod
  DebugSensoryInputModule(InputModuleManager _inputModuleManager){
    super(_inputModuleManager);
    for (int i = 0; i < 256; i++) {
      keysPressed.put(i, false);
    }
  }
  
  void update(){
    checkCombination();
    
    // Random movement for debug
    var data = new RawMotionData(); data.speed = map(noise(frameCount * 0.1), 0, 1, -0.5, 0.5);
    //inputModuleManager.OnRawMotionDetected(data);
  }
  
  void OnkeyPressed(int keyPress){
   
    keysPressed.put(keyPress, true);
  }
  
  void OnkeyReleased(int keyPress){
    keysPressed.put(keyPress, false);
  }
  
  void checkCombination() {
    // Verifica la combinazione di tasti
    boolean ctrlPressed = keysPressed.get(17); // Codice tasto Ctrl
    
    if(ctrlPressed == true){
      
      if(prevWasShake){
        inputModuleManager.OnShakeEvent(ShakeDimention.NONE);
        prevWasShake = false;
      }
      for(int i = 49; i< 58; i++){
        if(keysPressed.get(i)){
          inputModuleManager.OnWeelActivated(map(i, 49, 57, -1, 1));
        }
      }
    }
    else{
      if(keysPressed.get(48)){
        inputModuleManager.OnShakeEvent(ShakeDimention.NONE); prevWasShake = false;
      }
      else if(keysPressed.get(49)){
        inputModuleManager.OnShakeEvent(ShakeDimention.SUBTLE);        prevWasShake = true;
      }
      else if(keysPressed.get(50)){
        inputModuleManager.OnShakeEvent(ShakeDimention.LITTLE_ATTRACTING);        prevWasShake = true;
      }
      else if(keysPressed.get(51)){
        inputModuleManager.OnShakeEvent(ShakeDimention.LONG_ATTRACTING);        prevWasShake = true;
      }
      else if(keysPressed.get(52)){
        inputModuleManager.OnShakeEvent(ShakeDimention.LITTLE_NOT_ATTRACTING);        prevWasShake = true;
      }
      else if(keysPressed.get(53)){
        inputModuleManager.OnShakeEvent(ShakeDimention.STRONG_HOOKING);        prevWasShake = true;
      }
      else if(keysPressed.get(54)){
        inputModuleManager.OnShakeEvent(ShakeDimention.STRONG_NOT_HOOKING);        prevWasShake = true;
      }
      else{
        if(prevWasShake){
          inputModuleManager.OnShakeEvent(ShakeDimention.NONE); prevWasShake = false;
        }
      }
    }
  }
  
  
}
