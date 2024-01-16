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
   int acc_x;
   int acc_y;
   int acc_z;
   RawMotionData(int acc_x, int acc_y, int acc_z){
         this.acc_x = acc_x;
         this.acc_y = acc_y;
         this.acc_z = acc_z;
   }
}

class SensoryInputModule{
  
  // Make use of the SerializationUtility static class and its methods to properly serialize the data to forward
  
  InputModuleManager inputModuleManager;
  
  // use inputModuleManager to notify the game with all the data comming from the rod
  SensoryInputModule(InputModuleManager _inputModuleManager){
    inputModuleManager = _inputModuleManager;
  }
  
}
