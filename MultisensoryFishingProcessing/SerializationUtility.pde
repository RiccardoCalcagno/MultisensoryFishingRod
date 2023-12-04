import java.net.DatagramSocket;
import java.net.DatagramPacket;
import java.net.InetAddress;
import java.net.SocketException;

static class SerializationUtility{
  
    GameManager gameManager;
    public SerializationUtility(GameManager gameManager){
        this.gameManager = gameManager;
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
      
      datagramSocket = new DatagramSocket(6969);
    
      while(!serverExit){
          // Read data from the client
          byte[] receiveData = new byte[10];
          DatagramPacket receivePacket = new DatagramPacket(receiveData, receiveData.length);
          datagramSocket.receive(receivePacket);
          String line = (new String(receivePacket.getData(), 0, receivePacket.getLength())).split("\n")[0];
          System.out.println("RECEIVED: " + line);
    
          // Check what the client sent
          String[] lineSplit = line.split("/");
          if(lineSplit[0].equals("raw")){
              // do something
              String[] rawSplit = lineSplit[1].split(":");
              switch(rawSplit[0])
              {
                  case "acc_x":
                      //gameManager.player.acc_x = float.Parse(rawSplit[1]);
                      break;
              }
          }
          else if(lineSplit[0].equals("event")){
              // do something else
              switch(lineSplit[1]){
                  case "" : break;
              }
          }
      }
    }
    catch(Exception se){
      se.printStackTrace();
    }
  
    datagramSocket.close();
  }
}
