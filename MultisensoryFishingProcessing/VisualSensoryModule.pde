class VisualSensoryModule extends AbstSensoryOutModule{ 
  
  PImage fishImg; 
  
    VisualSensoryModule(OutputModulesManager outputModulesManager){
    super(outputModulesManager);
   
    fishImg = loadImage("fish.png");
    fishImg.resize(180, 180);
  }
  
  void OnRodStatusReading(RodStatusData dataSnapshot){
    
    drawFish();
  }
  
  void drawFish() {

    translate(width/2, height/2);
    //fill(color(240, 240, 255 ,100));
    //box(boxsize);
    
    var fish = outputModulesManager.getFish();
    var fishDeltaPos = fish.getDeltaPos();
    var fishPose = fish.getPos();
    
    var directionX = fishDeltaPos[0];
    var directionY = fishDeltaPos[1];
    var directionZ = fishDeltaPos[2];
    
    // Apply rotation based on direction of motion
    //float thetaY = atan2(-directionX, -directionZ);
    //float thetaX = atan2(directionY, sqrt(directionZ * directionZ + directionX * directionX));
    
    float thetaY = atan2(directionX, directionZ) - PI/2;
    float thetaX = atan2(-directionY, sqrt(directionZ * directionZ + directionX * directionX));
    
    pushMatrix();
    translate(fishPose[0], fishPose[1], fishPose[2]);
    rotateY(thetaY);
    rotateX(thetaX);
    fill(0);
    noStroke();
     imageMode(CENTER);
    image(fishImg, 0, 0); // Draw the fish image
    popMatrix();
  }
}
