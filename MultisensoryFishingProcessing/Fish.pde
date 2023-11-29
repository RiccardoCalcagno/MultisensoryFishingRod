
class Fish implements PublicFish{
  
  float prevPosX, prevPosY, prevPosZ; 
  float posX, posY, posZ;
  
  float[] getPos(){
    return new float[] {posX, posY, posZ};
  }
  float[] getDeltaPos(){
    return new float[] {directionX, directionY, directionZ};
  }
  float getIntentionality(){
    return intentionality;
  }
  
  float foodX = 0, foodY = 0, foodZ = 0; // Food position at (0, 0, 0)
  float intentionality; // Intentionality of the fish (0 to 1)
  float stepSize; // Size of each step
  float boxsize;
  PImage fishImg; 
  float directionX;
  float directionY;
  float directionZ;
  
  Fish() {
    boxsize = 1300;
    //size(1400, 1400, P3D);
    posX = random(-boxsize/2, boxsize/2);
    posY = random(-boxsize/2, boxsize/2);
    posZ = random(-boxsize/2, boxsize/2);
    
    fishImg = loadImage("fish.png");
    fishImg.resize(180, 180);
  }
  
  
  void UpdatePosition(){
    
    float targetX = foodX - posX;
    float targetY = foodY - posY;
    float targetZ = foodZ - posZ;
    
    // Normalize target direction
    float distance = sqrt(targetX*targetX + targetY*targetY + targetZ*targetZ);
    targetX /= distance;
    targetY /= distance;
    targetZ /= distance;
    
    // Update fish's position based on intention
    intentionality = 0.1;
    stepSize = 2;
    float noiseScale = 0.01;
    float noiseX = map(noise(frameCount * noiseScale), 0, 1, -0.1, 0.1);
    float noiseY = map(noise((frameCount + 1000)* noiseScale), 0, 1, -0.1, 0.1);
    float noiseZ = map(noise((frameCount + 2000) * noiseScale), 0, 1, -0.1, 0.1);
    float noisedistance = sqrt(noiseX*noiseX + noiseY*noiseY + noiseZ*noiseZ);
    noiseX /= noisedistance;
    noiseY /= noisedistance;
    noiseZ /= noisedistance;
    
    prevPosX = posX;
    prevPosY = posY;
    prevPosZ = posZ;
    
    posX += (noiseX * (1 - intentionality) + targetX * intentionality )* stepSize;
    posY += (noiseY * (1 - intentionality) + targetY * intentionality )* stepSize;
    posZ += (noiseZ * (1 - intentionality) + targetZ * intentionality )* stepSize;
    
    // Constrain fish within the cube
    posX = constrain(posX, -boxsize/2, boxsize/2);
    posY = constrain(posY, -boxsize/2, boxsize/2);
    posZ = constrain(posZ, -boxsize/2, boxsize/2);   
  }
  
  void drawFish() {
    background(255);

    translate(width/2, height/2);
    //fill(color(240, 240, 255 ,100));
    //box(boxsize);
    
    directionX = posX - prevPosX;
    directionY = posY - prevPosY;
    directionZ = posZ - prevPosZ;
    
    // Apply rotation based on direction of motion
    float thetaY = atan2(-directionX, -directionZ);
    float thetaX = atan2(directionY, sqrt(directionZ * directionZ + directionX * directionX));
    
    pushMatrix();
    translate(posX, posY, posZ);
    rotateY(thetaY);
    rotateX(thetaX);
    fill(0);
    noStroke();
     imageMode(CENTER);
    image(fishImg, 0, 0); // Draw the fish image
    popMatrix();
  }
}
