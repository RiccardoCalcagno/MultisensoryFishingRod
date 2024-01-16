import java.net.DatagramSocket;
import java.net.DatagramPacket;
import java.net.InetAddress;
import java.net.SocketException;

// ALLOWED RECEIVED MESSAGES: 
// raw/enc:value 
// raw/acc:value;value;value

static int SERVER_PORT = 6969;
static int TINY_ML_PORT = 6001;
static String TINY_ML_IP_value = "127.0.0.1";
static InetAddress TINY_ML_IP;
static GameManager gameManager;

static class SerializationUtility{
  
    public SerializationUtility(GameManager game){
        
        gameManager = game;
        // Start a thread with server
        Thread server_thread = new Thread(new ServerThread());
        server_thread.start();
        System.out.println("Starting server thread on port: "+String.valueOf(SERVER_PORT));
    }

    public void startServer(){
        
    }
}

static class ServerThread extends Thread {

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
                  
                  int acc_x = Integer.valueOf(value_str.split(";")[0]);
                  int acc_y = Integer.valueOf(value_str.split(";")[1]);
                  int acc_z = Integer.valueOf(value_str.split(";")[2]);
                  
                  System.out.println(String.format("%d;%d;%d",x,y,z)); 
                  
                  RawMotionData data = new RawMotionData(acc_x,acc_y,acc_z);
                  gameManager.OnRawMotionDetected(data); 
                  
              }  

          }
          else if(lineSplit[0].equals("tinyML")){
            // from Python, detected by TinyML
            String event = lineSplit[1].split(":")[1];
            System.out.println("EVENT: "+event);
            
            switch(event){
               case "none":
                 gameManager.OnShakeEvent(ShakeDimention.NONE);
                 gameManager.sensoryModules.get(2).OnFishLost();
                 break;
               case "subtle":
                 gameManager.OnShakeEvent(ShakeDimention.SUBTLE);
                 break;
               case "little_attracting":
                 gameManager.OnShakeEvent(ShakeDimention.LITTLE_ATTRACTING);
                 break;
               case "long_attracting":
                 gameManager.OnShakeEvent(ShakeDimention.LONG_ATTRACTING);
                 break;
               case "little_NOT_attracting":
                 gameManager.OnShakeEvent(ShakeDimention.LITTLE_NOT_ATTRACTING);
                 break;
               case "strong_hooking":
                 gameManager.OnShakeEvent(ShakeDimention.STRONG_HOOKING);
                 break;
               case "strong_NOT_hooking":
                 gameManager.OnShakeEvent(ShakeDimention.STRONG_NOT_HOOKING);
                 break;
               }
          }
      }
    }
    catch(Exception se){
      se.printStackTrace();
    }
  
    server.close();
  }
}
