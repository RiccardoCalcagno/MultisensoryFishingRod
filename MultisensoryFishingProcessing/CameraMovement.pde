import processing.serial.*;
import processing.net.*;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.Socket;


// ------------------------------------------------------------------------------------------------
//                     CAMERA MOVEMENT / POSITION PROVIDER - GUI AWARE 
// ------------------------------------------------------------------------------------------------

interface CameraStreamReader {
  void OnData(String data);
}

class CameraMovement implements CameraStreamReader {

  // ------------------------------------------- FINE-TUNABLES CONSTANTS -------------------------------------------  
    
  float scaleX = 1.5;
  float scaleY = 1.5;
  float scaleZ = 1.5;
  
  
  // ------------------------------------------- FIELDS -------------------------------------------  
  
  PVector cameraPosition;
  PVector lastPosRequired;

  // ------------------------------------------- DEPENDENCIES -------------------------------------------  
  
  GameManager gameManager;
  PApplet parent;
  processing.serial.Serial myPort;
  CameraServerThread server;




  CameraMovement(GameManager _gameManager, PApplet _parent) {
    gameManager = _gameManager;
    parent = _parent;
    cameraPosition = new PVector(width/2, height/2.0, width);
    lastPosRequired = cameraPosition.copy();
  }

  void OnData(String data) {
    if (data != "") {
      var numbers = float(split(data, ','));
      cameraPosition = MapDataToCamPosition(numbers);
    }
  }

  PVector getCameraPosition() {
    
    if(PVector.dist(lastPosRequired, cameraPosition) > 50){ //20){      // TODO Remove
      lastPosRequired = PVector.lerp(lastPosRequired, cameraPosition, 0.2);
    }
    else{
     lastPosRequired = cameraPosition;
    }
    return lastPosRequired;
  }

  void TryConnectToFacePoseProvider() {

    String portName = "COM2"; // Cambia con la tua porta seriale
    int baudRate = 115200; // Cambia con il baud rate corretto

    try {
      myPort = new processing.serial.Serial(parent, portName, baudRate);
      server = new CameraServerThread(myPort, this);
      
      server.start();
    }
    catch(Exception se) {
      gameManager.GetDebugUtility().Println("ERROR: Can not start camera movement server, probably you need to create COM1 and COM2 virtually, internal error: "+se);
    }
  }

  PVector MapDataToCamPosition(float[] data) {
    
    float x = width/2.0 - data[0]*scaleX;
    float y = height/2.0 + data[1]*scaleY;
    float z = width/2.0 + data[2]*scaleZ;
    return PVector.lerp(cameraPosition, new PVector(x, y, z), 0.5);
  }
  
}



// ------------------------------------------------------------------------------------------------
//                     COMUNICATION UTILITY WITH THE CAMERA MOVMENT PROCESS
// ------------------------------------------------------------------------------------------------

static class CameraServerThread extends Thread {

  processing.serial.Serial myPort;
  CameraStreamReader cameraStreamReader;

  boolean isReceiving = false;
  String currentMessage = "";
  Boolean serverExit = false;

  public CameraServerThread(processing.serial.Serial _myPort, CameraStreamReader _cameraStreamReader) {
    super();
    cameraStreamReader = _cameraStreamReader;
    myPort = _myPort;
  }

  public void run() {
    try {
      while (!serverExit) {
        while (myPort.available() > 0) {
          char inChar = (char)myPort.read();
          if (inChar == '_') {
            cameraStreamReader.OnData(currentMessage);
            isReceiving = true;
            currentMessage = "";
          } else {
            currentMessage+=inChar;
          }
        }
        sleep(1);
      }
      println("STOPPING PORT ");
      myPort.stop();
    }
    catch(Exception se) {
      println("EXCEPTION ", se);
      myPort.stop();
    }
  }
  
}




/*
static class CameraServerThread extends Thread {

  CameraStreamReader cameraStreamReader;
  BufferedReader bufferedInput;
  Socket client = null;

  public CameraServerThread(CameraStreamReader _cameraStreamReader) {
    super();
    cameraStreamReader = _cameraStreamReader;
  }

  public void run() {
    try 
    {
      client = new Socket("127.0.0.1", 5000);
      bufferedInput = new BufferedReader(new InputStreamReader(client.getInputStream()));
    }
    catch(Exception se) {
      se.printStackTrace();
    }   

    while (isDisposed() == false){
      try 
      {
        if(client.isConnected() == false || bufferedInput.ready() == false){
         continue; 
        }
        String data = bufferedInput.readLine();
        if(data != null)
        {
          data = new String(data.getBytes(), "UTF-8");
          try 
          {
            if(data.startsWith("HeadPose:")){
              data = data.substring(9);
              println("arrived from camera pos server: "+data);
              String[] datas =  data.split(",");
              float X = float(datas[0]);
              float Y = float(datas[2]);
              float Z = float(datas[4]);
              
              cameraStreamReader.OnData(X, Y, Z);
            }
          }
          catch(Exception se) {
            println("arrived wrong data: "+data);
          }
        }
        else{
         println("received null string from Camera server"); 
        }
        
        Thread.sleep(20);
      }
      catch(Exception se) {
        se.printStackTrace();
      }   
    }
  }
  
  boolean isDisposed(){
    return client == null;
  }
  
  void Dispose(){
    if(isDisposed() == false){
      try {
        client.close();
      } catch(Exception e) { println("in disposing haptic thread, can not close DatagramSoket, exception: "+e);}
      client = null;
    }
  }
  
}*/
