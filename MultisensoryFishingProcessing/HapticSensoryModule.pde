static String MESSAGE = "set/act:%d";
static int CLIENT_PORT = 7000;
static int ESP_PORT = 6969;
static String ESP_IP_value = "192.168.1.90";
static InetAddress ESP_IP;
static DatagramSocket client;
static int BUFFER_MAX_SIZE = 20;
static int MIN_VIBRATOR_VALUE = 90;
static int MAX_VIBRATOR_VALUE = 255; 
static int HALF_VIBRATOR_VALUE = 180;



enum FishingEvent{
     NONE,
     ROD_READ,
     FISH_TASTE_BAIT,
     FISH_HOOKED,
     FISH_LOST,
     FISH_CAUGHT,
     WIRE_ENDED,
     END
}


class HapticSensoryModule extends AbstSensoryOutModule {
  
  ClientThread client_thread = null;
  float lastTension;
  
  HashMap<FishingEvent, Integer> priorities = new HashMap<FishingEvent, Integer>();
  
  Integer millisecSinceEvent;
  
  FishingEvent event = FishingEvent.NONE;
      

  HapticSensoryModule(OutputModulesManager outputModulesManager) {
    super(outputModulesManager);
    
    priorities.put(FishingEvent.NONE, 1);
    priorities.put(FishingEvent.ROD_READ, 1);
    priorities.put(FishingEvent.FISH_TASTE_BAIT, 2);
    priorities.put(FishingEvent.FISH_HOOKED, 4);
    priorities.put(FishingEvent.FISH_LOST, 4);
    priorities.put(FishingEvent.FISH_CAUGHT, 4);
    priorities.put(FishingEvent.WIRE_ENDED, 4);
    priorities.put(FishingEvent.END, 10);
  }
    

  void ResetGame(){
     if(client_thread!= null){
       client_thread.Dispose();
       client_thread = null;
     }
     
     event = FishingEvent.NONE;
     millisecSinceEvent = null;
     lastTension = 0;
     
     client_thread = new ClientThread(this); 
     client_thread.start();
     System.out.println("Starting client Haptic thread on port: "+String.valueOf(CLIENT_PORT));
  }
  
  // Once per gameLoop
  void OnRodStatusReading(RodStatusData dataSnapshot) {
      lastTension = dataSnapshot.coefficentOfWireTension;
      if(outputModulesManager.isFishHooked() == true){
        if(lastTension > 0.1){
          SetEvent(FishingEvent.ROD_READ);           
        }
        else{
          SetEvent(FishingEvent.NONE);
        }
      }
      
      if(keyPressed & outputModulesManager.GetDebugUtility().debugLevels.get(DebugType.InputAsKeyboard) == true){
        debug_for_event();
      }
  }  
  // Asyncronous meningful events
  void OnShakeOfRod(ShakeDimention rodShakeType) {
  }
  void OnFishTasteBait() {
    SetEvent(FishingEvent.FISH_TASTE_BAIT);
  }
  void OnFishHooked() {
    SetEvent(FishingEvent.FISH_HOOKED);
  }
  void OnFishLost() {
    SetEvent(FishingEvent.FISH_LOST);
  }
  void OnFishCaught() {
    SetEvent(FishingEvent.FISH_CAUGHT);
  }
  void OnWireEndedWithNoFish() {
    SetEvent(FishingEvent.WIRE_ENDED);
  }
  void OnEndGame(){
    SetEvent(FishingEvent.END);
    client_thread.Dispose();
  }
  
  
  
  // Pairs, the first value mean the intensity the second for how many millisec, if the time is < 0 then there is not an end, the next event will change the status
  private int[][] getPattern(FishingEvent event){
    
    switch(event){
         
       case ROD_READ:
         float tens = lastTension;
         int value = int(map(lastTension, 0.1, 1, MIN_VIBRATOR_VALUE, MAX_VIBRATOR_VALUE));
         return new int[][] { {255, 20}, {value, -1} };
         
       case FISH_TASTE_BAIT:
         return new int[][] { {MAX_VIBRATOR_VALUE, 100}, { 0, -1 } };
         
       case FISH_LOST:
       case WIRE_ENDED:
         return new int[][] { {HALF_VIBRATOR_VALUE, 500}, { 0, 500 }, { HALF_VIBRATOR_VALUE, 500 }, { 0, 500}, {HALF_VIBRATOR_VALUE, 1000}, { 0, -1 }  };
       
       case FISH_HOOKED:
         return new int[][] { {MAX_VIBRATOR_VALUE, 200}, { HALF_VIBRATOR_VALUE, 100 }, {MAX_VIBRATOR_VALUE, 100}, { HALF_VIBRATOR_VALUE, 150 }, {MAX_VIBRATOR_VALUE, 200}, { HALF_VIBRATOR_VALUE, 100 }};

       case FISH_CAUGHT:
         return new int[][] { {HALF_VIBRATOR_VALUE, 200}, { 0, 180 }, { HALF_VIBRATOR_VALUE, 200 }, { 0, 180}, {HALF_VIBRATOR_VALUE, 200} , { 0, 180 }, { HALF_VIBRATOR_VALUE, 200 }, { 0, 180}, {HALF_VIBRATOR_VALUE, 200}, { 0, -1 }  };

       case NONE:
       case END:
       default:
         return new int[][]{ { 0 , -1} };
     }
  }
  private int ReadCurrentIndexOfPattern(int[][] pattern, int millisecFromStart){
    
    int indx = -1;
    int sumMillis = 0;
    for(int i=0; i<pattern.length; i++){
      if((sumMillis <= millisecFromStart) && (pattern[i][1] <0 || millisecFromStart < sumMillis+pattern[i][1] )){
        indx = i;
      }
      sumMillis += pattern[i][1];
    }
   return indx; 
  }

  
  private void SetEvent(FishingEvent _event){
    
    if(event != FishingEvent.END && ( _event!= FishingEvent.ROD_READ || event!= FishingEvent.ROD_READ)){
      var patternChosed = getPattern(event);
      var currentIndx = ReadCurrentIndexOfPattern(patternChosed, getMillisFromEvent());
      
      if(currentIndx < 0 || priorities.get(_event) >= priorities.get(event)){
        millisecSinceEvent = null; 
        event = _event;   
      } 
    }
  }
  
  private int getMillisFromEvent(){
   if(millisecSinceEvent != null){
     return millis() - millisecSinceEvent;
   }
   return 0;
  }
  
  public int getCurrentValue(){
    String text="";
    if(millisecSinceEvent == null){
      millisecSinceEvent = millis();
      text+="started Pattern: ";
    }
    else{
      text+="                 ";
    }
    var patternChosed = getPattern(event);
    var index = ReadCurrentIndexOfPattern(patternChosed,  getMillisFromEvent());
    text+=event+("               ".substring((event.toString()).length()))+" "+index;
    
    int outValue = -1;
    if(index>=0){
      outValue = patternChosed[index][0];
    }
    outputModulesManager.GetDebugUtility().Println((text+"  "+outValue+"   "+nf(lastTension, 2, 3)+"        "+frameCount), true);
    return outValue;
  }
  
  
  void debug_for_event(){ 
            
      switch(key) {
        case('a'):
          SetEvent(FishingEvent.ROD_READ);
          break;
        case('s'):
          SetEvent(FishingEvent.FISH_TASTE_BAIT);
          break;
        case('d'):
          SetEvent(FishingEvent.FISH_HOOKED);
          break;
        case('f'):
          SetEvent(FishingEvent.FISH_LOST);
          break;
        case('g'):
          SetEvent(FishingEvent.FISH_CAUGHT);
          break;
        case('h'):
          SetEvent(FishingEvent.WIRE_ENDED);
          break;
        case('j'):
          SetEvent(FishingEvent.END);
          break;
      }
    }  
}




class ClientThread extends Thread {
  
  HapticSensoryModule hapticSensoryModule;
  int precedentValue = 0;
  
  ClientThread(HapticSensoryModule _hapticSensoryModule){
    hapticSensoryModule = _hapticSensoryModule;
  }

  public void run() {
    try {
      client = new DatagramSocket(CLIENT_PORT);
      ESP_IP = InetAddress.getByName(ESP_IP_value);   
      while (isDisposed() == false){

        int value = hapticSensoryModule.getCurrentValue();
       
        if(value < 0){
          value = precedentValue;
        }
        send_message_to_vibrators(value);
        precedentValue = value;
        
        Thread.sleep(30);
      }
    }
    catch(Exception se) {
      se.printStackTrace();
    }   
  }
  
  boolean isDisposed(){
    return client == null;
  }
  
  void Dispose(){
    if(isDisposed() == false){
      try {
        send_message_to_vibrators(0);
        send_message_to_vibrators(0);
        send_message_to_vibrators(0);
        sleep(10);
        send_message_to_vibrators(0);
        sleep(100);
        send_message_to_vibrators(0);
        send_message_to_vibrators(0);
        send_message_to_vibrators(0);
      }
      catch(Exception se) {
        println("in disposing haptic thread, can not put asleep vibrators, exception: "+se);
      }  
      try {
        client.close();
        println("Client Close");
      } catch(Exception e) { println("in disposing haptic thread, can not close DatagramSoket, exception: "+e);}
      client = null;
    }
  }
  
  void send_message_to_vibrators(int value) {
    try {
      String message = String.format(MESSAGE, value);
      byte[] data = new byte[100];
      data = message.getBytes();
      DatagramPacket packet = new DatagramPacket(data, data.length, ESP_IP, ESP_PORT);
      client.send(packet);
      System.out.println("SEND: " + message+ " "+ frameCount);
    }
    catch(Exception se) {
      se.printStackTrace();
    }
  }

}
