
class Fish implements PublicFish{
  
  float prevPosX, prevPosY, prevPosZ; 
  float posX, posY, posZ;
  
  float[] getPos(){
    return new float[] {posX, posY, posZ};
  }
  float[] getDeltaPos(){
    return direction;
  }
  float getIntentionality(){
    return intentionality;
  }
  
  float stepSize = 2; // Size of each step
  float maxAngularSpeed = 0.01; // Modifica la velocità angolare massima secondo necessità
  float distanceFromFoodWhenStartToDecellerate = 50;

  int boxsize;
  float foodX, foodY, foodZ; // Food position at (0, 0, 0)
  float intentionality; // Intentionality of the fish (0 to 1)
  float[] direction = new float[3];
  
  GameManager gameManager;
  
  Fish(GameManager _gameManager) {
    gameManager = _gameManager;
    
    intentionality = 0.5;
    
    foodX = 0; 
    foodY = 0;
    foodZ = 0;
     
    boxsize = gameManager.getSizeOfAcquarium();
    posX = random(-boxsize/2, boxsize/2);
    posY = random(-boxsize/2, boxsize/2);
    posZ = random(-boxsize/2, boxsize/2);
    
    calculateDeltaFood(direction);
  }
  
  
  void UpdatePosition() {
    
    float[] deltaTarget = calculateDeltaTarget();

    adjustDirectionBasedOnTerget(deltaTarget); 
    
    float currentStepSize = adjustSpeed();
    
    posX += direction[0] * currentStepSize;
    posY += direction[1] * currentStepSize;
    posZ += direction[2] * currentStepSize;
    
    // Constrain fish within the cube
    posX = constrain(posX, -boxsize/2, boxsize/2);
    posY = constrain(posY, -boxsize/2, boxsize/2);
    posZ = constrain(posZ, -boxsize/2, boxsize/2);
  }
  
  
  
  
  float[] calculateDeltaTarget(){
    float[] deltaFood = new float[3];
    calculateDeltaFood(deltaFood);
    
    // Update fish's position based on intention
    float noiseScale = 0.01;
    float noiseX = map(noise(frameCount * noiseScale), 0, 1, -0.1, 0.1);
    float noiseY = map(noise((frameCount + 1000) * noiseScale), 0, 1, -0.1, 0.1);
    float noiseZ = map(noise((frameCount + 2000) * noiseScale), 0, 1, -0.1, 0.1);
    float noisedistance = sqrt(noiseX*noiseX + noiseY*noiseY + noiseZ*noiseZ);
    noiseX /= noisedistance;
    noiseY /= noisedistance;
    noiseZ /= noisedistance;
    
    // Calculate the weighted combination of random movement and intentional movement
    float[] deltaTarget = new float[3];
    deltaTarget[0] = lerp(noiseX, deltaFood[0], intentionality);
    deltaTarget[1] = lerp(noiseY, deltaFood[1], intentionality);
    deltaTarget[2] = lerp(noiseZ, deltaFood[2], intentionality);
    
    return deltaTarget;
  }
  
  
  void adjustDirectionBasedOnTerget(float[] deltaTarget){
    
    float targetAngleX = atan2(deltaTarget[1], deltaTarget[0]);
    float targetAngleY = atan2(deltaTarget[2], sqrt(deltaTarget[0] * deltaTarget[0] + deltaTarget[1] * deltaTarget[1]));

    float currentAngleX = atan2(direction[1], direction[0]);
    float currentAngleY = atan2(direction[2], sqrt(direction[0] * direction[0] + direction[1] * direction[1]));

    float angleDiffX = targetAngleX - currentAngleX;
    float angleDiffY = targetAngleY - currentAngleY;
    angleDiffX = atan2(sin(angleDiffX), cos(angleDiffX));
    angleDiffY = atan2(sin(angleDiffY), cos(angleDiffY));
    angleDiffX = constrain(angleDiffX, -maxAngularSpeed, maxAngularSpeed);
    angleDiffY = constrain(angleDiffY, -maxAngularSpeed, maxAngularSpeed);

    currentAngleX += angleDiffX;
    currentAngleY += angleDiffY;
    
    direction[0] = cos(currentAngleX) * cos(currentAngleY);
    direction[1] = sin(currentAngleX) * cos(currentAngleY);
    direction[2] = sin(currentAngleY);
  }
  
  
  float adjustSpeed(){
    float[] deltaFood = new float[3];
    float foodDistance = calculateDeltaFood(deltaFood);
    
    float coefficentOfSpeed = 1;
    
    // Decellerate fish when near to food
    if(foodDistance < distanceFromFoodWhenStartToDecellerate){
      
      float coeff_HowMuchDivergingFormFood = 0;
      float[] normDistanceFromFood = new float[3];
      normDistanceFromFood[0] = deltaFood[0] - direction[0];
      normDistanceFromFood[1] = deltaFood[1] - direction[1];
      normDistanceFromFood[2] = deltaFood[2] - direction[2];
      float distanceInGeometricPhereOfFood =  sqrt(normDistanceFromFood[0]*normDistanceFromFood[0] + normDistanceFromFood[1]*normDistanceFromFood[1] + normDistanceFromFood[2]*normDistanceFromFood[2]);
      // max distence = sqrt(2*2+2*2+2*2) = sqrt(12)
      coeff_HowMuchDivergingFormFood = distanceInGeometricPhereOfFood / sqrt(12);
      
      float coeff_HowMuchIsNearToFood = foodDistance / distanceFromFoodWhenStartToDecellerate;
      
      coefficentOfSpeed = map(coeff_HowMuchIsNearToFood, 0, 1, coeff_HowMuchDivergingFormFood, 1);
    }
    return lerp(0, stepSize, coefficentOfSpeed); 
  }
  
  
  
  float calculateDeltaFood(float[] out_DeltaFood){
      out_DeltaFood[0] = foodX - posX;
      out_DeltaFood[1] = foodY - posY;
      out_DeltaFood[2] = foodZ - posZ;
      
      // Normalize target direction
      float foodDistance = sqrt(out_DeltaFood[0]*out_DeltaFood[0] + out_DeltaFood[1]*out_DeltaFood[1] + out_DeltaFood[2]*out_DeltaFood[2]);
      out_DeltaFood[0] /= foodDistance;
      out_DeltaFood[1] /= foodDistance;
      out_DeltaFood[2] /= foodDistance;
      return foodDistance;
  }
}
