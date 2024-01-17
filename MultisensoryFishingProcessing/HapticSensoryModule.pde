import java.util.concurrent.TimeUnit;
import java.util.List;


static String MESSAGE = "set/act:%d";
static int CLIENT_PORT = 7000;
static int ESP_PORT = 6969;
static String ESP_IP_value = "192.168.1.90";
static InetAddress ESP_IP;
static DatagramSocket client;
static int BUFFER_MAX_SIZE = 20;
static int MIN_VIBRATOR_VALUE = 50;



enum FishingEvent{
     DEFAULT,
     FISH_TASTE_BAIT,
     FISH_HOOKED,
     FISH_LOST,
     FISH_CAUGHT,
     WIRE_ENDED,
     END
}



class HapticSensoryModule extends AbstSensoryOutModule {
  
  ClientThread client_thread;
  FloatList buffer_wireTensions;

  HapticSensoryModule(OutputModulesManager outputModulesManager) {
    super(outputModulesManager);
    buffer_wireTensions = new FloatList();
    client_thread = new ClientThread(this); 
    client_thread.start();
    System.out.println("Starting client thread on port: "+String.valueOf(CLIENT_PORT));
  }
  
  void send_message_to_vibrators(int value) {
    try {
      String message = String.format(MESSAGE, value);
      byte[] data = new byte[100];
      data = message.getBytes();
      DatagramPacket packet = new DatagramPacket(data, data.length, ESP_IP, ESP_PORT);
      client.send(packet);
      System.out.println("SEND: " + message);
    }
    catch(Exception se) {
      se.printStackTrace();
    }
  }

  // Once per gameLoop
  void OnRodStatusReading(RodStatusData dataSnapshot) {
      float wireTension = dataSnapshot.coefficentOfWireTension;
      buffer_wireTensions.append(wireTension);
  }
  
  // Asyncronous meningful events
  void OnShakeOfRod(ShakeDimention rodShakeType) {
  }
  
  void OnFishTasteBait() {
    println("Fish has tasted the bait!!!");
    client_thread.SetEvent(FishingEvent.FISH_TASTE_BAIT);
  }

  void OnFishHooked() {
    client_thread.SetEvent(FishingEvent.FISH_HOOKED);
  }

  void OnFishLost() {
    client_thread.SetEvent(FishingEvent.FISH_LOST);
  }
  void OnFishCaught() {
    client_thread.SetEvent(FishingEvent.FISH_CAUGHT);
  }
  void OnWireEndedWithNoFish() {
    client_thread.SetEvent(FishingEvent.WIRE_ENDED);
  }
}




class ClientThread extends Thread {
  
  HapticSensoryModule hapticSensoryModule;
  boolean exitClient = false;
  FishingEvent event;
  
  ClientThread(HapticSensoryModule _hapticSensoryModule){
    hapticSensoryModule = _hapticSensoryModule;
    event = FishingEvent.DEFAULT;
  }

  public void run() {
    try {
      client = new DatagramSocket(CLIENT_PORT);
      ESP_IP = InetAddress.getByName(ESP_IP_value);   
      while (!exitClient){
        event = GetEvent();
        manageEvent(event);
      }
    }
    catch(Exception se) {
      se.printStackTrace();
    }   
  }
  
  void SetEvent(FishingEvent event){
     this.event = event;
     println(event);
  }
  
  FishingEvent GetEvent(){
     return this.event;
  }
  
  void manageEvent(FishingEvent event){
     switch(event){
       case FISH_HOOKED:
         if(hapticSensoryModule.buffer_wireTensions.size() == BUFFER_MAX_SIZE){
            int valueToSend = 0;
            float wireTension = hapticSensoryModule.buffer_wireTensions.get(BUFFER_MAX_SIZE-1); //get the last value
            if(wireTension < 0){ 
              valueToSend = Math.round(MIN_VIBRATOR_VALUE - wireTension * (255-MIN_VIBRATOR_VALUE));
            }
            else if(wireTension < 0){
              valueToSend = Math.round(MIN_VIBRATOR_VALUE + wireTension * (255-MIN_VIBRATOR_VALUE));
            }
            hapticSensoryModule.send_message_to_vibrators(valueToSend);
            hapticSensoryModule.buffer_wireTensions.clear();
         }
         break;
         
       case FISH_TASTE_BAIT:
         hapticSensoryModule.send_message_to_vibrators(255);
         delay(100);
         hapticSensoryModule.send_message_to_vibrators(0);
         this.SetEvent(FishingEvent.DEFAULT);
         break;
         
       case FISH_LOST:
         hapticSensoryModule.send_message_to_vibrators(0);
         this.SetEvent(FishingEvent.DEFAULT);
         break;
       
       case FISH_CAUGHT:
         hapticSensoryModule.send_message_to_vibrators(0);
         this.SetEvent(FishingEvent.DEFAULT);
         break;
         
       case WIRE_ENDED:
         hapticSensoryModule.send_message_to_vibrators(0);
         this.SetEvent(FishingEvent.DEFAULT);
         break;
         
       case END:
         hapticSensoryModule.send_message_to_vibrators(0);
         exitClient = true;
         break;
         
       case DEFAULT:
         break;
     }
  }
}
