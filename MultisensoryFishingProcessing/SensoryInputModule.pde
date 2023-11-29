interface InputModuleManager{

  void OnShakeEvent(ShakeDimention type);
  
  // speedOfWireRetrieving is from -1 to 1. Normalized. negative speed for retreiving the wire, positive velocities for relising wire.
  void OnWeelActivated(float speedOfWireRetrieving);
  
  void OnRawMotionDetected(RawMotionData data);
}


// TODO
// Manuel definirà quelle che possono essere le feature più esplicative per descrivere il movimento come velocities and accellerations.
// it is usefull, for instance, for the PureData to add sounds for the rod that is swinging
class RawMotionData{
   float speed;
   float accelleration;
}


class SensoryInputModule{
  
  // Make use of the SerializationUtility static class and its methods to properly serialize the data to forward
  
  InputModuleManager inputModuleManager;
  
  SensoryInputModule(InputModuleManager _inputModuleManager){
    inputModuleManager = _inputModuleManager;
  }
  
  
  
  
}
