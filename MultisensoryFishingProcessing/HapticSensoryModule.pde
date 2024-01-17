import java.util.concurrent.TimeUnit;
import java.util.List;
// abstact class => inherit classes (extends) can implement methods cited in the abstract class
// implementare tali funzioni. Esse vengono chiamate nel main in base allo stato del gioco
// fare un thread con client che invia dati UDP alla ESP


static String MESSAGE = "set/act:%d";
static int CLIENT_PORT = 7000;
static int ESP_PORT = 6969;
static String ESP_IP_value = "192.168.1.90";
static InetAddress ESP_IP;
static DatagramSocket client;
static Thread client_thread;
static List<Float> buffer = new ArrayList<Float>();

class HapticSensoryModule extends AbstSensoryOutModule {

  HapticSensoryModule(OutputModulesManager outputModulesManager) {
    super(outputModulesManager);
    client_thread = new Thread(new ClientThread()); // probabilmente lo devo fare per ogni funzione
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
      //System.out.println("SEND: " + message);
    }
    catch(Exception se) {
      se.printStackTrace();
    }
  }


  // Once per gameLoop
  void OnRodStatusReading(RodStatusData dataSnapshot) {
    Thread OnRodStatusReading_thread = new Thread (new OnRodStatusReadingThread(dataSnapshot) );
    OnRodStatusReading_thread.start();
  }

  // Asyncronous meningful events
  void OnShakeOfRod(ShakeDimention rodShakeType) {
  }

  // event fired when the fish is touching the hook. I (Riccardo) change its movemnts in the way that 1 event of tasting the bait has at least 0.8 sec of distance between each others
  void OnFishTasteBait() {
    Thread OnFishHooked_thread = new Thread (new OnFishTasteBaitThread());
    OnFishHooked_thread.start();
  }

  void OnFishHooked() {
    Thread OnFishHooked_thread = new Thread (new OnFishHookedThread());
    OnFishHooked_thread.start();
  }

  void OnFishLost() {
    Thread OnFishLost_thread = new Thread (new OnFishLostThread());
    OnFishLost_thread.start();
  }
  void OnFishCaught() {
    Thread OnFishCaught_thread = new Thread (new OnFishCaughtThread());
    OnFishCaught_thread.start();
  }
  void OnWireEndedWithNoFish() {
    Thread OnWireEndedWithNoFish_thread = new Thread (new OnWireEndedWithNoFishThread());
    OnWireEndedWithNoFish_thread.start();
  }
}

void send_message_to_vibrators(int value) {
    try {
      String message = String.format(MESSAGE, value);
      byte[] data = new byte[100];
      data = message.getBytes();
      DatagramPacket packet = new DatagramPacket(data, data.length, ESP_IP, ESP_PORT);
      client.send(packet);
      //System.out.println("SEND: " + message);
    }
    catch(Exception se) {
      se.printStackTrace();
    }
}



class ClientThread extends Thread {

  public void run() {
    try {
      client = new DatagramSocket(CLIENT_PORT);
      ESP_IP = InetAddress.getByName(ESP_IP_value);
    }
    catch(Exception se) {
      se.printStackTrace();
    }
  }

  void exit_Client() {
    client.close();
  }
}


class OnFishTasteBaitThread extends Thread {
  
  public void run() {
    try {
      //System.out.println("Start OnFishTasteBait Thread");
      send_message_to_vibrators(255);
      delay(100);
      send_message_to_vibrators(0);
    }
    catch(Exception se) {
      se.printStackTrace();
    }
  }
}

class OnFishCaughtThread extends Thread {
  
  public void run() {
    try {
      send_message_to_vibrators(0);
    }
    catch(Exception se) {
      se.printStackTrace();
    }
  }
}


class OnFishLostThread extends Thread {
  
  public void run() {
    try {
      send_message_to_vibrators(0);
    }
    catch(Exception se) {
      se.printStackTrace();
    }
  }
}

class OnFishHookedThread extends Thread {
  
  public void run() {
    try {
      send_message_to_vibrators(255);
      delay(1000);
      send_message_to_vibrators(0);
    }
    catch(Exception se) {
      se.printStackTrace();
    }
  }
}

class OnWireEndedWithNoFishThread extends Thread {
  
  public void run() {
    try {
      send_message_to_vibrators(0);
    }
    catch(Exception se) {
      se.printStackTrace();
    }
  }
}

int startTime;

class OnRodStatusReadingThread extends Thread {

  RodStatusData dataSnapshot;
  Float wireTension;
  int valueToSend;
  int cachedValueToSend = 0;
  int MIN_VIBRATOR_VALUE = 20;
  
  OnRodStatusReadingThread(RodStatusData dataSnapshot){
     this.dataSnapshot = dataSnapshot;
  }
  
  public void run() {
    try {
          if(buffer.size() == 0){
             startTime = millis();
          }
          buffer.add(dataSnapshot.coefficentOfWireTension);
        
          if(buffer.size() == 20){
            wireTension = buffer.get(0);
            buffer.clear();
            //println(String.format("Time: %d ms ", millis() - startTime));
            if(wireTension == 0.0){
              valueToSend = 0;
            }
            else if(wireTension < 0){ 
              valueToSend = Math.round(MIN_VIBRATOR_VALUE - wireTension * (255-MIN_VIBRATOR_VALUE));
            }
            else{
              valueToSend = Math.round(MIN_VIBRATOR_VALUE + wireTension * (255-MIN_VIBRATOR_VALUE));
            }
            
            if (cachedValueToSend != valueToSend){
              cachedValueToSend = valueToSend;
              send_message_to_vibrators(valueToSend);
              delay(500);
              send_message_to_vibrators(0);
            }
          }
    }
    catch(Exception se) {
      se.printStackTrace();
    }
  }
}
