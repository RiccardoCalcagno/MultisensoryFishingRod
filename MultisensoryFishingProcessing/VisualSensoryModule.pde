class VisualSensoryModule extends AbstSensoryOutModule{ 
  
  float scaleScene;
  PImage sandImg;
  PImage fishImg; 
  PImage fishFromTop;
  int fishPXSize = 230;
  
  
  VisualSensoryModule(OutputModulesManager outputModulesManager){
    super(outputModulesManager);
    
    // this coefficent allow us to take advantage of a good perspective of the camera and avoid the fish
    scaleScene =  (2.0 +(float)outputModulesManager.getSizeOfAcquarium() / (float)min(width, height)) / 3.0;
   
    fishImg = loadImage("fish.png");
    fishImg.resize(fishPXSize, fishPXSize);
    
    //TODO fishFromTop
    
    sandImg = loadImage("sand.jpg");
    sandImg.resize(width, width);
    
  }
  
  // this can be used als as draw cicle
  void OnRodStatusReading(RodStatusData dataSnapshot){
    
    background(85, 146, 200); // Colore azzurro per l'acqua    
    
    drawBottom();
     
    
    if(outputModulesManager.isFishHooked() == true){
      drawSceneFishHooked();
    }
    else{
      drawSceneFishNotHooked();
    }
    
  }

  void drawBottom(){
    pushMatrix();
    translate(width/2,  height, - width/2);
    scale(scaleScene);
    rotateX(PI / 2.0);
    imageMode(CORNERS);
    image(sandImg, -width * 10, -width * 10, width*20, width*20);
    popMatrix();
  }
  
  void drawSceneFishNotHooked() {
    
    noLights();
    
    var fish = outputModulesManager.getFish();
    var fishDeltaPos = fish.getDeltaPos();
    var fishPose = fish.getPos();
    
    var directionX = fishDeltaPos[0];
    var directionY = fishDeltaPos[1];
    var directionZ = fishDeltaPos[2];
    
    float thetaY = atan2(directionX, directionZ) - PI/2;
    float thetaX = atan2(-directionY, sqrt(directionZ * directionZ + directionX * directionX));
   
    
    pushMatrix();
    translate(width/2 + fishPose[0], height/2 +fishPose[1], fishPose[2]);
    
    // this coefficent allow us to take advantage of a good perspective of the camera and avoid the fish
    // to go out of the field of view
    scale(scaleScene);
    
    rotateY(thetaY);
    rotateX(thetaX);
    fill(0);
    imageMode(CENTER);
    image(fishImg, 0, 0); // Draw the fish image

    
    popMatrix();
  }
  
  
  void drawSceneFishHooked(){
    noLights();
  }
  
  
  
  
  
}