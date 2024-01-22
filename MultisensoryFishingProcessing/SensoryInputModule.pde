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
  
  DebugUtility GetDebugUtility();
}

// TODO
// Manuel definirà quelle che possono essere le feature più esplicative per descrivere il movimento come velocities and accellerations.
// it is usefull, for instance, for the PureData to add sounds for the rod that is swinging
// NORMALIZZATI
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
   

static int SERVER_PORT = 6969;
static int TINY_ML_PORT = 5000;
static String TINY_ML_IP_value = "127.0.0.1";
static InetAddress TINY_ML_IP;
static GameManager gameManager;

class SensoryInputModule{
  
  // Make use of the SerializationUtility static class and its methods to properly serialize the data to forward
  
  InputModuleManager inputModuleManager;
  
  ServerThread server;
  
  float speed = 0;
  String shake = "";
  RawMotionData data = new RawMotionData();
  boolean isRightHanded;
  
  DebugUtility debugUtility;
  
  // use inputModuleManager to notify the game with all the data comming from the rod
  SensoryInputModule(InputModuleManager _inputModuleManager, boolean _isRightHanded){
    
    inputModuleManager = _inputModuleManager;
    debugUtility = inputModuleManager.GetDebugUtility();
    isRightHanded = _isRightHanded;
  }
 
  
  public void Start(){
        // Start a thread with server
    server = new ServerThread(this);
    server.start();
    debugUtility.Println("Starting server thread on port: "+String.valueOf(SERVER_PORT));
    
    debugUtility.SubscribeToDebugLoop(new UpdateFunction() {
      @Override
      void execute(DebugUtility debugUtility, GameManager gameManager){
        if(debugUtility.debugLevels.get(DebugType.ConsoleAlowRawRodInputs) == true){
          var vecAcc = getAccellerationInScene(data, true);
          debugUtility.Println("RetrivingWire: "+nfp(speed, 1, 2)+"     Acc: "+nfp( vecAcc.x,1, 3)+", "+nfp(vecAcc.y,1, 3)+", "+nfp(vecAcc.z,1, 3)+"        LastShake: "+shake, true);
        }
      }
    });
  }
  
  void OnWeelActivated(float _speed){
    if(isRightHanded == false){
      _speed = -_speed;
    }
    _speed = constrain(_speed / 12, -1, 1);
    
    speed = _speed;
    inputModuleManager.OnWeelActivated(_speed); 
  }
  
  void handleShakeEvent(String type){
    shake = type;
    //println(shake+" "+frameCount);     
    switch(type){
     case "none":
       inputModuleManager.OnShakeEvent(ShakeDimention.NONE);
       break;
     case "little_attracting":
       inputModuleManager.OnShakeEvent(ShakeDimention.LITTLE_ATTRACTING);
       break;
     case "long_attracting":
       inputModuleManager.OnShakeEvent(ShakeDimention.LONG_ATTRACTING);
       break;
     case "strong_hooking":
       inputModuleManager.OnShakeEvent(ShakeDimention.STRONG_HOOKING);
       break;
     case "long_NOT_attracting":
       inputModuleManager.OnShakeEvent(ShakeDimention.STRONG_NOT_HOOKING);
       break;
     default:
       println("ATTENTION, CASE NOT HANDLED: "+type);
     }
  }
  
  void OnRawMotionDetected(RawMotionData _data){
    data = _data;
    inputModuleManager.OnRawMotionDetected(_data);
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
                  float value = -Float.parseFloat(value_str);
                  inputModule.OnWeelActivated(value);
              }
              
              else if(k.equals("acc")){
                  
                  // forward to python for tinyML 
                  byte[] sendData = new byte[100];
                  sendData = line.getBytes();
                  DatagramPacket packet = new DatagramPacket(sendData, sendData.length, TINY_ML_IP, TINY_ML_PORT);
                  server.send(packet);
                  // System.out.println("SEND: " + line); 
                  
                  int max_acc = 32800;
                  float acc_x = Float.valueOf(value_str.split(";")[0])/max_acc;
                  float acc_y = Float.valueOf(value_str.split(";")[1])/max_acc;
                  float acc_z = Float.valueOf(value_str.split(";")[2])/max_acc;
                  
                  //System.out.println(String.format("ACCELLERAZIONI %f;%f;%f",acc_x,acc_y,acc_z)); 
                  
                  RawMotionData data = new RawMotionData(acc_x,acc_y,acc_z);
                  inputModule.OnRawMotionDetected(data);  
              }  

          }
          else if(lineSplit[0].equals("tinyML")){
            // from Python, detected by TinyML
            String event = lineSplit[1].split(":")[1];
            
            inputModule.handleShakeEvent(event);
          }
          
          
          // TODO Verify if it has made the think better
          sleep(1);
      }
    }
    catch(Exception se){
      se.printStackTrace();
    }
  
    server.close();
  }
}
