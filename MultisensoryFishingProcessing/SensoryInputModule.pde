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
  
  int lastPress = 0;
  char lastChar = ' ';
  // use inputModuleManager to notify the game with all the data comming from the rod
  DebugSensoryInputModule(InputModuleManager _inputModuleManager){
    super(_inputModuleManager);
  }
  
  void update(){
    lastPress--;
    if(lastPress == 0){
      OnChar('1');
    }
  }
  
  void OnkeyPressed(char keyPress){
   
    if(lastPress < 0 || lastChar != keyPress){
      OnChar(keyPress);
    }
    
    lastPress = 20;
  }
  
  void OnChar(char keyPress){
    
    if(keyPress >= '1' && keyPress <= '7'){
       switch(keyPress){
       case '1':
         inputModuleManager.OnShakeEvent(ShakeDimention.NONE);
         break;
       case '2':
         inputModuleManager.OnShakeEvent(ShakeDimention.SUBTLE);
         break;
       case '3':
         inputModuleManager.OnShakeEvent(ShakeDimention.LITTLE_ATTRACTING);
         break;
       case '4':
         inputModuleManager.OnShakeEvent(ShakeDimention.LONG_ATTRACTING);
         break;
       case '5':
         inputModuleManager.OnShakeEvent(ShakeDimention.LITTLE_NOT_ATTRACTING);
         break;
       case '6':
         inputModuleManager.OnShakeEvent(ShakeDimention.STRONG_HOOKING);
         break;
       case '7':
         inputModuleManager.OnShakeEvent(ShakeDimention.STRONG_NOT_HOOKING);
         break;
       }
    }
    
    lastChar = keyPress;
  }
}
