import java.net.DatagramSocket;
import java.net.DatagramPacket;
import java.net.InetAddress;
import java.net.SocketException;

static int server_port = 6969;
static int python_port = 6000;

static GameManager gameMng;

static class SerializationUtility{
  
    public SerializationUtility(GameManager gameManager){
        
        gameMng = gameManager;
        // Start a thread with server
        Thread server = new Thread(new ServerThread());
        server.start();
        System.out.println("Starting server thread...");
    }

    public void startServer(){
        
    }
}

static class ServerThread extends Thread {

  Boolean serverExit = false;
  public void run() {
    DatagramSocket datagramSocket = null;
    
    try{
      
      datagramSocket = new DatagramSocket(server_port);
    
      while(!serverExit){
          // Read data from the client
          byte[] receiveData = new byte[100];
          DatagramPacket receivePacket = new DatagramPacket(receiveData, receiveData.length);
          datagramSocket.receive(receivePacket);
          String line = (new String(receivePacket.getData(), 0, receivePacket.getLength())).split("\n")[0];
          System.out.println("RECEIVED: " + line);
    
          // ALLOWED MESSAGES: 
          // raw/enc:value 
          // raw/acc:value,value,value

          String[] lineSplit = line.split("/");
          
          if(lineSplit[0].equals("raw")){
              
              String[] raw = lineSplit[1].split(":"); // key:value
              String k = raw[0];
              String value_str = raw[1];
              
              if(k.equals("enc")){
                  float value = Float.parseFloat(value_str);
                  gameMng.OnWeelActivated(value);
                  // gameManager.OnRawMotionDetected(data); // rumore della wheel che gira
              }
              
              else if(k.equals("acc")){
              
                  // forward to python for tinyML 
                  String msg = line;
                  byte[] sendData = new byte[100];
                  sendData = msg.getBytes();
                  InetAddress address = InetAddress.getByName("127.0.0.1");
                  int port = python_port;
                  DatagramPacket packet = new DatagramPacket(sendData, sendData.length, address, port);
                  datagramSocket.send(packet);
                  System.out.println("SEND: " + msg); 

                  // send data to PureData
                  // gameManager.OnRawMotionDetected(data);
              }  

          }
          else if(lineSplit[0].equals("tinyML")){
            // from Python, detected by TinyML
            String event = lineSplit[1].split(":")[1];
            System.out.println("EVENT: "+event);
            // gameMng.OnShakeEvent(event);
          }
      }
    }
    catch(Exception se){
      se.printStackTrace();
    }
  
    datagramSocket.close();
  }
}


// enum ShakeDimention{
//      NONE,
//      SUBTLE,
//      LITTLE_ATTRACTING,
//      LONG_ATTRACTING,
//      LITTLE_NOT_ATTRACTING,
//      STRONG_HOOKING,
//      STRONG_NOT_HOOKING
// }
