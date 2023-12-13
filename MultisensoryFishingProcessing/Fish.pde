
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
     
    boxsize = gameManager.getSizeOfAcquarium();
  }
  
  void Restart(){
   
    pos = new PVector(random(-boxsize/2, boxsize/2), random(-boxsize/2, boxsize/2), random(-boxsize/2, boxsize/2));
    
    intentionality = 0.5;
  }
  
  
  void UpdatePosition() {
    
    PVector deltaTarget = calculateDeltaTarget();

    direction = adjustDirectionBasedOnTerget(deltaTarget); 
    
    direction.setMag(adjustSpeed());
    
    pos.add(direction);
    
    // Constrain fish within the cube
    pos.x = constrain(pos.x, -boxsize/2, boxsize/2);
    pos.y = constrain(pos.y, -boxsize/2, boxsize/2);
    pos.z = constrain(pos.z, -boxsize/2, boxsize/2);
    
    //DebugHeadColliderAndSpeedVector();
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
  
  
  PVector adjustDirectionBasedOnTerget(PVector deltaTarget){
    
    return deltaTarget.copy();
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
      
      coefficentOfSpeed = map(coeff_HowMuchIsNearToFood, 0, 1, lerp(coeff_HowMuchDivergingFormFood, 1, 0.9), 1);
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
  
  
  void DebugHeadColliderAndSpeedVector(){
    PVector mouthPos = PVector.sub(pos, getFishRotation().setMag(PublicFish.fishHeight / 4));
    pushMatrix();
    scale(player.scaleScene);
    translate(width/2 + mouthPos.x, height/2 + mouthPos.y, mouthPos.z);
    stroke(color(255, 0, 0));
    sphere(PublicFish.fishHeight / 4);
    popMatrix();
    pushMatrix();
    scale(player.scaleScene);
    PVector enlargedDirection = direction.copy().mult(100);
    translate(width/2 + pos.x + enlargedDirection.x, height/2 + pos.y + enlargedDirection.y, pos.z + enlargedDirection.z);
    stroke(color(0, 255, 0));
    sphere(10);
    line(0,0,0, -enlargedDirection.x, -enlargedDirection.y, -enlargedDirection.z);
    popMatrix();
  }
}
