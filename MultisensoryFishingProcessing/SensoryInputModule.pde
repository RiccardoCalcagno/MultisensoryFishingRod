import java.net.DatagramSocket;
import java.net.DatagramPacket;
import java.net.InetAddress;
import java.net.SocketException;



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
   RawMotionData(){
   }
}


static int SERVER_PORT = 6969;
static int TINY_ML_PORT = 6001;
static String TINY_ML_IP_value = "127.0.0.1";
static InetAddress TINY_ML_IP;
static GameManager gameManager;

class SensoryInputModule{
  
  // Make use of the SerializationUtility static class and its methods to properly serialize the data to forward
  
  InputModuleManager inputModuleManager;
  
  ServerThread server;
  
  // use inputModuleManager to notify the game with all the data comming from the rod
  SensoryInputModule(InputModuleManager _inputModuleManager){
    inputModuleManager = _inputModuleManager;
    // Start a thread with server
    server = new ServerThread(this);
    server.start();
    System.out.println("Starting server thread on port: "+String.valueOf(SERVER_PORT));
        
  }
  
  void handleShakeEvent(String type){
    switch(type){
     case "none":
       inputModuleManager.OnShakeEvent(ShakeDimention.NONE);
       //inputModuleManager.sensoryModules.get(2).OnFishLost();
       break;
     case "subtle":
       inputModuleManager.OnShakeEvent(ShakeDimention.SUBTLE);
       break;
     case "little_attracting":
       inputModuleManager.OnShakeEvent(ShakeDimention.LITTLE_ATTRACTING);
       break;
     case "long_attracting":
       inputModuleManager.OnShakeEvent(ShakeDimention.LONG_ATTRACTING);
       break;
     case "little_NOT_attracting":
       inputModuleManager.OnShakeEvent(ShakeDimention.LITTLE_NOT_ATTRACTING);
       break;
     case "strong_hooking":
       inputModuleManager.OnShakeEvent(ShakeDimention.STRONG_HOOKING);
       break;
     case "strong_NOT_hooking":
       inputModuleManager.OnShakeEvent(ShakeDimention.STRONG_NOT_HOOKING);
       break;
     }
  }
  
  void OnRawMotionDetected(RawMotionData data){
    inputModuleManager.OnRawMotionDetected(data);
  }
  
}


class ServerThread extends Thread {
  
  SensoryInputModule inputModule;
  
  public ServerThread(SensoryInputModule _inputModule){
    inputModule = _inputModule;
  }

  Boolean serverExit = false;
  public void run() {
    DatagramSocket server = null;
    
    try{
      
      server = new DatagramSocket(SERVER_PORT);
      TINY_ML_IP = InetAddress.getByName(TINY_ML_IP_value);
    
      while(!serverExit){
          // Read data from the client
          
          byte[] receiveData = new byte[100];
          DatagramPacket receivePacket = new DatagramPacket(receiveData, receiveData.length);
          server.receive(receivePacket);
          String line = (new String(receivePacket.getData(), 0, receivePacket.getLength())).split("\n")[0];
          // System.out.println("RECEIVED: " + line);

          String[] lineSplit = line.split("/");
          
          if(lineSplit[0].equals("raw")){
              
              String[] raw = lineSplit[1].split(":"); // key:value
              String k = raw[0];
              String value_str = raw[1];
              
              if(k.equals("enc")){
                  float value = Float.parseFloat(value_str);
                  gameManager.OnWeelActivated(value);
              }
              
              else if(k.equals("acc")){
                  
                  // forward to python for tinyML 
                  byte[] sendData = new byte[100];
                  sendData = line.getBytes();
                  DatagramPacket packet = new DatagramPacket(sendData, sendData.length, TINY_ML_IP, TINY_ML_PORT);
                  server.send(packet);
                  // System.out.println("SEND: " + line); 
                  
                  int max_acc = 32800;
                  int acc_x = Integer.valueOf(value_str.split(";")[0])/max_acc;
                  int acc_y = Integer.valueOf(value_str.split(";")[1])/max_acc;
                  int acc_z = Integer.valueOf(value_str.split(";")[2])/max_acc;
                  
                  System.out.println(String.format("%d;%d;%d",acc_x,acc_y,acc_z)); 
                  
                  RawMotionData data = new RawMotionData(acc_x,acc_y,acc_z);
                  inputModule.OnRawMotionDetected(data);  
              }  

          }
          else if(lineSplit[0].equals("tinyML")){
            // from Python, detected by TinyML
            String event = lineSplit[1].split(":")[1];
            System.out.println("EVENT: "+event);
            
            inputModule.handleShakeEvent(event);
          }
      }
    }
    catch(Exception se){
      se.printStackTrace();
    }
  
    server.close();
  }
}
