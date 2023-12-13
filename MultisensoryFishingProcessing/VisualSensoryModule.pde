class VisualSensoryModule extends AbstSensoryOutModule{ 
  
  
  float numAlgaePerPxSquared = 0.0000004;
  int[] tintColor = new int[]{200, 220, 255};
  int resizeAlgaeWidth = 100;
  
  
  float scaleScene;
  PImage sandImg, waterSurface, fishImg, fishFromTop, tallAlga, shortAlga;
  float fishWidth, fishHeight;
  float actualThetaY, actualThetaZ;
  PVector[] algaePos;
  int[] algaeType;
  float[] algaeRotation;
  
  int numAlgae;
  
  float boxSize;
  float fieldSize;
  
  VisualSensoryModule(OutputModulesManager outputModulesManager){
    super(outputModulesManager);
    
    boxSize = outputModulesManager.getSizeOfAcquarium();
    fieldSize = boxSize * 30;
    // this coefficent allow us to take advantage of a good perspective of the camera and avoid the fish
    scaleScene =  (2.0 +(float)boxSize / (float)min(width, height)) / 3.0;
   
    PublicFish fish = outputModulesManager.getFish();
    fishWidth = fish.fishWidth;
    fishHeight = fish.fishHeight;
    fishImg = loadImage("fishNotCentered.png");
    tallAlga = loadImage("algaeTall.png");
    shortAlga = loadImage("algaeShort.png");
    tallAlga.resize((int)(resizeAlgaeWidth), (int)(4.51*resizeAlgaeWidth));
    shortAlga.resize((int)(resizeAlgaeWidth), (int)(2.438*resizeAlgaeWidth));
    
    fishImg.resize((int)fishWidth, (int)fishHeight);
    
    //TODO fishFromTop

    sandImg = loadImage("sand.jpg");
    sandImg.resize(2*width, 2*width);
    waterSurface  = loadImage("waterSurface.jpg");
    waterSurface = getWithAlpha(waterSurface, 50);
    //sandImg.resize(2*width, 2*width);
    
    numAlgae = (int)(fieldSize*fieldSize*numAlgaePerPxSquared);
    algaePos = new PVector[numAlgae];
    algaeType = new int[numAlgae];
    algaeRotation = new float[numAlgae];
    for(int i=0; i<numAlgae; i++){
      algaePos[i] = new PVector(randomGaussian()*fieldSize/7, 0, randomGaussian()*fieldSize/7);
      algaeType[i] = int(random(2));
      algaeRotation[i] = random(0, PI/2);
    }
  }
  
  // this can be used als as draw cicle
  void OnRodStatusReading(RodStatusData dataSnapshot){
      
    rotateCamera();
    
    drawBottom();
    
    drawAlgae();
    
    if(outputModulesManager.isFishHooked() == true){
      drawSceneFishHooked();
    }
    else{
      drawSceneFishNotHooked();
    }
  }
  
  void drawAlgae(){
    
    for(int i=0; i<numAlgae; i++){
      for(int j=0; j<2; j++){   
        pushMatrix();
        scale(scaleScene);
        translate(width/2 + algaePos[i].x,  height,  algaePos[i].z);
        rotateY(algaeRotation[i] + (PI/2)*(int(j)));
        rotateZ(PI);
        fill(0);
        imageMode(CORNER);
        if(algaeType[i] == 0){
          image(tallAlga, -resizeAlgaeWidth/2, 0, resizeAlgaeWidth/2, resizeAlgaeWidth*10); 
        }
        else{
          image(shortAlga, -resizeAlgaeWidth/2, 0, resizeAlgaeWidth/2, resizeAlgaeWidth*5); 
        }
        popMatrix();
      }
    } 
   
  }
  
  void rotateCamera(){
    //scale(scaleScene);
    float angle = (TWO_PI / 100) * millis() / 1000.0;   
    
    float cameraX = (width/2) + (width) * cos(angle);
    float cameraZ = (width) * sin(angle);
    // Imposta la posizione della camera
    camera(cameraX, height/2.0, cameraZ, width/2, height/2, 0, 0, 1, 0);
    
    /* FOR DEBUG
    if((frameCount / 100) %2 == 0){
      camera(width/2,  height/2, width/2, width/2, height/2, 0, 0, 1, 0);
    }
    else{
      camera(width/2,  0, 110, width/2, height/2, 0, 0, 1, 0);
    }*/
  }

  void drawBottom(){
    textureWrap(REPEAT); 
        
    pushMatrix();
    
    scale(scaleScene);
    
    translate(width/2,  0, 0);
    rotateX(PI / 2.0);
    rotateZ(PI / 2.0);
    beginShape();
    tint(tintColor[0], tintColor[1], tintColor[2]);  
    texture(waterSurface);
    vertex(-fieldSize/2, -fieldSize/2, -fieldSize/2, fieldSize/2);
    vertex(-fieldSize/2,fieldSize/2, fieldSize/2, fieldSize/2);
    vertex(fieldSize/2, fieldSize/2, fieldSize/2, -fieldSize/2);
    vertex(fieldSize/2, -fieldSize/2, -fieldSize/2, -fieldSize/2);
    endShape();
    popMatrix();
    
    pushMatrix();

    scale(scaleScene);
    
    translate(width/2,  height, 0);
    rotateX(PI / 2.0);
    rotateZ(PI / 3.0);
    beginShape();
    texture(sandImg);
    vertex(-fieldSize/2, -fieldSize/2, -fieldSize/2, fieldSize/2);
    vertex(-fieldSize/2, fieldSize/2, fieldSize/2, fieldSize/2);
    vertex(fieldSize/2, fieldSize/2, fieldSize/2, -fieldSize/2);
    vertex(fieldSize/2, -fieldSize/2, -fieldSize/2, -fieldSize/2);
    endShape();

    popMatrix();
  }
  
  void drawSceneFishNotHooked() {
    
    var fish = outputModulesManager.getFish();
    var fishRotation = fish.getFishRotation();
    
    //var rotations = TrasformVectorInRotation(fishRotation, new PVector(1, 0, 0));//TrasformVectorInRotation(fishRotation, new PVector(1, 0, 0));
    var fishPose = fish.getPos();
    
    Vec3 powerdRotation = new Vec3(1,0,0);
    PVector rotationEnlarged = fishRotation.copy().setMag(100);
    PMatrix3D rotationMatrix = powerdRotation.lookAt(rotationEnlarged, new PVector(0, -1, 0));
    
    
    PVector targetGround = new PVector();
    rotationMatrix.mult(powerdRotation, targetGround);
    
    pushMatrix();
    scale(scaleScene);
    
    translate(width/2 + fishPose.x, height/2 +fishPose.y, fishPose.z);
    applyMatrix(rotationMatrix);   
    rotateY(-PI/2);
    rotateX(PI -targetGround.x);
    
    fill(0);
    imageMode(CENTER);
    image(fishImg, 0, 0); // Draw the fish image
    
    popMatrix();
    
    
    
    /* FOR DEBUG
    
    pushMatrix();
    scale(scaleScene);
    translate(width/2 + fishPose.x, height/2 +fishPose.y, fishPose.z);
    stroke(color(255, 0, 0));
    //sphere(10);
    //translate(rotationEnlarged.x, rotationEnlarged.y, rotationEnlarged.z);
    line(0,0,0, rotationEnlarged.x,rotationEnlarged.y, rotationEnlarged.z);
    //stroke(color(0, 255, 0));
    //sphere(10);
    popMatrix();
    

    pushMatrix();
    PVector versore = new PVector(100 , 0, 0);
    scale(scaleScene);
    translate(width/2 + fishPose.x, height/2 +fishPose.y, fishPose.z);
 
    applyMatrix(rotationMatrix);   
    rotateY(-PI/2);
    
    translate(versore.x, versore.y, versore.z);
    stroke(color(0,0,255));
    line(0,0,0,-versore.x,-versore.y, -versore.z);
    sphere(10);
    popMatrix();
    */
    
  }
  
  void drawSceneFishHooked(){
    
  }
  
}
