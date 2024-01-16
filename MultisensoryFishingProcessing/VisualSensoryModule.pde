class VisualSensoryModule extends AbstSensoryOutModule{ 
  
  // ------------------------------------------------------------------------------------------------
  //                                             PERSISTENCE 
  // ------------------------------------------------------------------------------------------------
  
  
  // ------------------------------------------- FINE-TUNABLES CONSTANTS -------------------------------------------  
  
  // Time with which the mouth of the fish will stay open, it has just a grafical meaning
  int timeMouthOpen = 10;
  
  // The void space (water) on top and under the box where the fish can swim (defined by boxSize)
  int verticalPaddingOfVisualBox  = -30;
  
  // Change the density of the algae spowned
  float numAlgaePerPxSquared = 0.00000007;  //0.00000024;
  
  // Change the size of the algae
  int resizeAlgaeWidth = 100;
  
  
  
  // ------------------------------------------- FIELDS -------------------------------------------  
  
  float scaleScene;
  PImage sandImg, waterSurface, fishImg, fishFromTop, tallAlga, shortAlga, fishOpenMouth;
  float actualThetaY_bait, actualThetaZ_bait;  PImage foodImg;
  float fishWidth, fishHeight;
  float actualThetaY, actualThetaZ;
  PVector[] algaePos;
  int[] algaeType;
  float[] algaeRotation;
  int[] tintColor = new int[]{220, 240, 255};
  int numAlgae;
  int isEating = 0;
  float boxSize;
  float fieldSize;
  
  
  // ------------------------------------------- DEPENDENCIES -------------------------------------------  
  
  PublicFish fish; 
  // outputModulesManager outputModulesManager, in  the abstract class
  
  
  // ------------------------------------------------------------------------------------------------
  //                                             CONSTRUCTOR 
  // ------------------------------------------------------------------------------------------------
  
  VisualSensoryModule(OutputModulesManager outputModulesManager){
    super(outputModulesManager);
    
    boxSize = outputModulesManager.getSizeOfAcquarium();
    fieldSize = boxSize * 30;
    // this coefficent allow us to take advantage of a good perspective of the camera and avoid the fish
    scaleScene =  (2.0 +(float)boxSize / (float)min(width, height)) / 3.0;
   
    fish = outputModulesManager.getFish();
    fishWidth = fish.fishWidth;
    fishHeight = fish.fishHeight;
    fishImg = loadImage("images/fishNotCentered.png");
    tallAlga = loadImage("images/algaeTall.png");
    fishOpenMouth = loadImage("images/fishOpenMouth.png");
    shortAlga = loadImage("images/algaeShort.png");
    tallAlga.resize((int)(resizeAlgaeWidth), (int)(4.51*resizeAlgaeWidth));
    shortAlga.resize((int)(resizeAlgaeWidth), (int)(2.438*resizeAlgaeWidth));
    
    fishImg.resize((int)fishWidth, (int)fishHeight);
    fishOpenMouth.resize((int)fishWidth, (int)fishHeight);
    foodImg = loadImage("images/food.png");
    foodImg.resize(80, 120);
    
    //TODO fishFromTop

    sandImg = loadImage("images/sand.jpg");
    sandImg.resize(2*width, 2*width);
    waterSurface  = loadImage("images/waterSurface.jpg");
    //waterSurface = getWithAlpha(waterSurface, 50);
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
  
  
  // ------------------------------------------------------------------------------------------------
  //                                       OVERWRITTEN METHODS 
  // ------------------------------------------------------------------------------------------------
  
  
  void OnFishTasteBait(){
    isEating= timeMouthOpen;
  }
  
  // this can be used als as draw cicle
  void OnRodStatusReading(RodStatusData dataSnapshot){
      
    isEating--;
    
    rotateCamera();
    
    drawBottom();
    
    drawAlgae();
    
    drawSceneFish();
    
    drawWireAndBait(dataSnapshot.coefficentOfWireTension);
  }
  
  
  
  // ------------------------------------------------------------------------------------------------
  //                                       DRAWING METHODS
  // ------------------------------------------------------------------------------------------------
  
  
  void drawAlgae(){
    
    for(int i=0; i<numAlgae; i++){
      for(int j=0; j<2; j++){   
        pushMatrix();
        scale(scaleScene);
        translate(width/2 + algaePos[i].x,  height - verticalPaddingOfVisualBox,  algaePos[i].z);
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
    var cameraPosition = outputModulesManager.getCameraPosition();
    // Imposta la posizione della camera
    camera(cameraPosition.x, cameraPosition.y, cameraPosition.z, width/2, height/2, 0, 0, 1, 0);
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
    
    translate(width/2,  0 + verticalPaddingOfVisualBox, 0);
    rotateX(PI / 2.0);
    rotateZ(PI / 2.0);
    beginShape();
    tint(255, 255, 255, 150);  
    texture(waterSurface);
    vertex(-fieldSize/2, -fieldSize/2, -fieldSize/2, fieldSize/2);
    vertex(-fieldSize/2,fieldSize/2, fieldSize/2, fieldSize/2);
    vertex(fieldSize/2, fieldSize/2, fieldSize/2, -fieldSize/2);
    vertex(fieldSize/2, -fieldSize/2, -fieldSize/2, -fieldSize/2);
    endShape();
    popMatrix();
    tint(tintColor[0], tintColor[1], tintColor[2], 255);  
        
    pushMatrix();

    scale(scaleScene);
    
    translate(width/2,  height - verticalPaddingOfVisualBox, 0);
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
  
  void drawSceneFish() {
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
    
    if(isEating > 0){
      image(fishOpenMouth, 0, 0);
    }
    else{
      image(fishImg, 0, 0);    
    }
    popMatrix();
    
    
    float angleOfOblique = abs(PI/2 - PVector.angleBetween(fishRotation, new PVector(0,1,0)));
    float widthShadow = PublicFish.fishWidth * map(angleOfOblique, 0, PI/2, 1, 0.4)/ 2;
    
    PVector posMiddleFish = PVector.sub(fish.getPos(), fishRotation.copy().setMag(PublicFish.fishWidth/4));
    drawShadow(posMiddleFish, fish.getFishRotation(), widthShadow);
    
    
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
  
  
  void drawShadow(PVector pos, PVector forward, float biggerCorner){
    PVector myforward = forward.copy();
    myforward.y = 0;
    //ombra.resize();
    pushMatrix();
    scale(scaleScene);
    translate(width/2 + pos.x,  height - verticalPaddingOfVisualBox - 2, pos.z);
    rotateX(PI / 2.0);
    float rotationAngle = PVector.angleBetween(new PVector(-1,0,0), myforward);
    if(PVector.angleBetween(new PVector(0,0,-1), myforward) > PI/2){
      rotationAngle = PI - rotationAngle;
    }
    rotateZ(rotationAngle);
    //imageMode(CENTER);
    noStroke();
    fill(0, 0, 0, 60);  
    ellipse(0,0,(int)(biggerCorner*1.2), (int)(biggerCorner*0.5));
    //image(ombra, 0, 0);   
    //tint(tintColor[0], tintColor[1], tintColor[2], 255);  
    popMatrix();
  }
  
  
  void drawWireAndBait(float wireFishTention) {
    
    VerletNode[] nodes = outputModulesManager.getNodesOfWire();
        
    pushMatrix();
    scale(scaleScene);
    translate(width/2, height/2, 0);
    hint(ENABLE_STROKE_PURE);
    for (int i = 0; i < nodes.length - 1; i++) {
      colorMode(RGB);
      strokeWeight(3);
      stroke(255 * wireFishTention, 0, 0);
      line(nodes[i].position.x, nodes[i].position.y, nodes[i].position.z,
           nodes[i+1].position.x, nodes[i+1].position.y, nodes[i+1].position.z);
    }
    hint(DISABLE_STROKE_PURE);
    popMatrix();    
    
    if(outputModulesManager.isFishHooked() == false){
      pushMatrix();
      scale(scaleScene);
      PVector hookPos = nodes[nodes.length-1].position;
      translate(width/2 + hookPos.x, height/2 + hookPos.y, hookPos.z);
      
      PVector directionLasts = PVector.sub(hookPos, nodes[nodes.length -2].position);
      
      float thetaY = atan2(directionLasts.x, directionLasts.z);
      float thetaZ = atan2(directionLasts.y, directionLasts.x);
      
      actualThetaY_bait = lerp(actualThetaY_bait, thetaY, 0.05);
      actualThetaZ_bait = lerp(actualThetaZ_bait, thetaZ, 0.05);
          
      rotateY(actualThetaY_bait);
      rotateX(-PI);
      rotateZ(actualThetaZ_bait);
      
      fill(0);
      imageMode(CENTER);
      image(foodImg, -35, 0); 
      popMatrix();
      
      drawShadow(hookPos, (new Vec3(directionLasts)).rotateX(PI/2), 120);
    }
  }
  
  
}
