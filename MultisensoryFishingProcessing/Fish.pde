
class Fish implements PublicFish{
  
  PVector prevPos, pos, prevDirectionLerped = null;
  float actualThetaX, actualThetaY, actualThetaZ;
  
  PVector getPos(){
    return pos.copy();
  }
  PVector getDeltaPos(){
    return direction.copy();
  }
  float getIntentionality(){
    return intentionality;
  }
 
  
  float stepSize = 2; // Size of each step
  float maxAngularSpeed = 0.1; // Modifica la velocità angolare massima secondo necessità
  float distanceFromFoodWhenStartToDecellerate = 50;

  int boxsize;
  float intentionality; // Intentionality of the fish (0 to 1)
  PVector direction = new PVector();
  
  GameManager gameManager;
  Player player;
  
  Fish(GameManager _gameManager, Player _player) {
    
    gameManager = _gameManager;
    player = _player;
    
    intentionality = 0.5;
     
    boxsize = gameManager.getSizeOfAcquarium();
    
    pos = new PVector(random(-boxsize/2, boxsize/2), random(-boxsize/2, boxsize/2), random(-boxsize/2, boxsize/2));
    
    calculateDeltaFood(direction);
  }
  
  
  void UpdatePosition() {
    
    PVector deltaTarget = calculateDeltaTarget();

    adjustDirectionBasedOnTerget(deltaTarget); 
    
    float currentStepSize = adjustSpeed();
    
    pos.x += direction.x * currentStepSize;
    pos.y += direction.y * currentStepSize;
    pos.z += direction.z * currentStepSize;
    
    // Constrain fish within the cube
    pos.x = constrain(pos.x, -boxsize/2, boxsize/2);
    pos.y = constrain(pos.y, -boxsize/2, boxsize/2);
    pos.z = constrain(pos.z, -boxsize/2, boxsize/2);
    
  }
  
  
  PVector getFishRotation(){
    
    PVector fishDeltaPos = getDeltaPos();
    
    if(prevDirectionLerped != null){
      
      prevDirectionLerped = PVector.lerp(prevDirectionLerped, fishDeltaPos, 0.03);
    }
    else{
      prevDirectionLerped = fishDeltaPos;
    }
    
    prevDirectionLerped.normalize();
    constrain(prevDirectionLerped.y, -0.35, 0.35);
    prevDirectionLerped.normalize();
    
    return prevDirectionLerped;
  }
  
  
  PVector calculateDeltaTarget(){
    PVector deltaFood = new PVector();
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
    PVector deltaTarget = new PVector(
      lerp(noiseX, deltaFood.x, intentionality),
      lerp(noiseY, deltaFood.y, intentionality),
      lerp(noiseZ, deltaFood.z, intentionality)
      );
    
    return deltaTarget;
  }
  
  
  void adjustDirectionBasedOnTerget(PVector deltaTarget){
    
    direction = deltaTarget.copy();
    
    //pos = new PVector(0,0,0);
    //direction = new PVector(0, 0, sin((float)(frameCount % 100) *2 *PI/ 100.0));
    /*
    float targetAngleX = atan2(deltaTarget.x, deltaTarget.x);
    float targetAngleY = atan2(deltaTarget.z, sqrt(deltaTarget.x * deltaTarget.x + deltaTarget.y * deltaTarget.y));

    float currentAngleX = atan2(direction.y, direction.x);
    float currentAngleY = atan2(direction.z, sqrt(direction.x * direction.x + direction.y * direction.y));

    float angleDiffX = targetAngleX - currentAngleX;
    float angleDiffY = targetAngleY - currentAngleY;
    angleDiffX = atan2(sin(angleDiffX), cos(angleDiffX));
    angleDiffY = atan2(sin(angleDiffY), cos(angleDiffY));
    
    //angleDiffX = constrain(angleDiffX, -maxAngularSpeed, maxAngularSpeed);
    //angleDiffY = constrain(angleDiffY, -maxAngularSpeed, maxAngularSpeed);

    currentAngleX += angleDiffX;
    currentAngleY += angleDiffY;
    
    direction.x = cos(currentAngleX) * cos(currentAngleY);
    direction.y = sin(currentAngleX) * cos(currentAngleY);
    direction.z = sin(currentAngleY);
    */
  }
  
  
  float adjustSpeed(){
    PVector deltaFood = new PVector();
    float foodDistance = calculateDeltaFood(deltaFood);
    
    float coefficentOfSpeed = 1;
    
    // Decellerate fish when near to food
    if(foodDistance < distanceFromFoodWhenStartToDecellerate){
      
      float coeff_HowMuchDivergingFormFood = 0;
      PVector normDistanceFromFood = PVector.sub(deltaFood, direction);
      float distanceInGeometricPhereOfFood = normDistanceFromFood.mag();
      // max distence = sqrt(2*2+2*2+2*2) = sqrt(12)
      coeff_HowMuchDivergingFormFood = distanceInGeometricPhereOfFood / sqrt(12);
      
      float coeff_HowMuchIsNearToFood = foodDistance / distanceFromFoodWhenStartToDecellerate;
      
      coefficentOfSpeed = map(coeff_HowMuchIsNearToFood, 0, 1, coeff_HowMuchDivergingFormFood, 1);
    }
    return lerp(0, stepSize, coefficentOfSpeed); 
  }
  
  
  
  
  
  
  float calculateDeltaFood(PVector out_DeltaFood){
      PVector hookPos = player.getHookPos();
      out_DeltaFood.x = hookPos.x - pos.x;
      out_DeltaFood.y = hookPos.y - pos.y;
      out_DeltaFood.z = hookPos.z - pos.z;
      
      // Normalize target direction
      float foodDistance = sqrt(out_DeltaFood.x*out_DeltaFood.x + out_DeltaFood.y*out_DeltaFood.y + out_DeltaFood.z*out_DeltaFood.z);
      out_DeltaFood.x /= foodDistance;
      out_DeltaFood.y /= foodDistance;
      out_DeltaFood.z /= foodDistance;
      return foodDistance;
  }
}
