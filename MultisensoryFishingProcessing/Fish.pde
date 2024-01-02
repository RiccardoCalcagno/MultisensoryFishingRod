
class Fish implements PublicFish{
  
   // coefficent expressing how much the valence of a certain shake is influencing the intentionality of the fish at each cicle
  float intensityOfValenceOfShakesForAttraction = 0.001;
  
  // Speed of the fish on free condition
  float stepSize = 2; 
  
  // Speed of the fish when hooked
  float stepSizeWhenHooked = 4;
  
  // threshold distance necessary to shape the speed of the fish in it environment, with food vision
  float distanceFromFoodWhenStartToDecellerate = 50;
  
  // dictionary (initialized in the constructor) defining the valence of each type of shake in regart to how much it should attract or distantiate the fish
  FloatDict shakesValenceForAttracting = new FloatDict();
  
  //timeSinceAttractionWasPositive indicate the number of cicle of positive attraction not interrupted by any episodes of negative attraction
  int timeSinceAttractionWasPositive;
  
  // reaching this value with the counter: timeSinceAttractionWasPositive define the maximum extream of intentionality unlocked.
  int strinkingTimeToReachOptimumAttractability = 500;
  
  // Usefull To introduce the forgetting parameter of the fish
  int timeOfLastInfluencingShake;
  
  // If no shake is introduced since numFramesAfterFishstartForgetting of frames, the intentionality of the fish start reaching the 0 with a certain speed (Forgetting)
  int numFramesAfterFishstartForgetting = 500;
  
  // Speed of forgetting his intentionality
  float speedOfForgettingIntentionality = 0.002;
  
  
  
  PVector prevPos, pos, prevDirectionLerped = null;
  float actualThetaX, actualThetaY, actualThetaZ;
  int boxsize;
  float intentionality; // Intentionality of the fish (0 to 1)
  PVector direction = new PVector();
  
  GameManager gameManager;
  Player player;
  
  
  PVector getPos(){
    return pos.copy();
  }
  PVector getDeltaPos(){
    return direction.copy();
  }
  float getIntentionality(){
    return intentionality;
  }
  
  Fish(GameManager _gameManager, Player _player) {
    
    shakesValenceForAttracting.set("NONE", 0);
    shakesValenceForAttracting.set("SUBTLE", 0.1);
    shakesValenceForAttracting.set("LITTLE_ATTRACTING", 1);
    shakesValenceForAttracting.set("LONG_ATTRACTING", 0.7);
    shakesValenceForAttracting.set("LITTLE_NOT_ATTRACTING", -0.4);
    shakesValenceForAttracting.set("STRONG_HOOKING", -2.5);
    shakesValenceForAttracting.set("STRONG_NOT_HOOKING", -3);
    
    gameManager = _gameManager;
    player = _player;
     
    boxsize = gameManager.getSizeOfAcquarium();
  }
  
  void Restart(){
   
    pos = new PVector(random(-boxsize/2, boxsize/2), random(-boxsize/2, boxsize/2), random(-boxsize/2, boxsize/2));
    
    timeSinceAttractionWasPositive = 0;
    timeOfLastInfluencingShake = 0;
    
    intentionality = 0;
  }
  
  
  void UpdatePosition() {
    
    direction = calculateDeltaTarget();
    
    direction.setMag(adjustSpeed());
    
    pos.add(direction);
    
    // Constrain fish within the cube
    pos.x = constrain(pos.x, -boxsize/2, boxsize/2);
    pos.y = constrain(pos.y, -boxsize/2, boxsize/2);
    pos.z = constrain(pos.z, -boxsize/2, boxsize/2);
    
    //DebugHeadColliderAndSpeedVector();
  }
  
  void UpdateIntentionality(ShakeDimention currentShake){
    
    // The fish when at the hook move frenetically and randomly
    if(gameManager.hasFish){
      intentionality = 0;
      return;
    }
    
    // Each type of shake as a valence (a weight) that put in comparison (good-bad) the shakes together, 
    // then intensityOfValenceOfShakesForAttraction is necessary to fine tuning all the intensity based on how much we want the intentionality to be responsive
    float valenceOfShake = shakesValenceForAttracting.get(currentShake.toString()) * intensityOfValenceOfShakesForAttraction;
    
    if(valenceOfShake != 0){

      intentionality += valenceOfShake;
      
      if(valenceOfShake < 0){
        timeSinceAttractionWasPositive = 0;
      }
      else if(timeSinceAttractionWasPositive<strinkingTimeToReachOptimumAttractability){
        timeSinceAttractionWasPositive++;
      }
      timeOfLastInfluencingShake = frameCount;
    }
    
    // Fish is progressively forgetting about its past intentionality if the hook is not more highlighted by any shake of the rod
    if(frameCount - timeOfLastInfluencingShake > numFramesAfterFishstartForgetting){
       intentionality = lerp(intentionality, 0, speedOfForgettingIntentionality);
    }
    
    // The intentionality can grow till a bigger upper limit of the user is doing the correct movments for a longer time, 
    // while as soon as he make a mistake the upper limit decrease immediately to its lowest, this because the fish got scared
    float upperEndOfIntentionality = map(timeSinceAttractionWasPositive, 0, strinkingTimeToReachOptimumAttractability, 0.4, 0.8);
    
    constrain(intentionality, -0.3, upperEndOfIntentionality);
        
        
    // Debug
    if(valenceOfShake != 0 || frameCount - timeOfLastInfluencingShake > numFramesAfterFishstartForgetting){
      println("Intent: "+intentionality+"         +Delta: "+valenceOfShake+"        tSincePositive: "+timeSinceAttractionWasPositive+"        MaxIntent: "+upperEndOfIntentionality);      
    }
  }

    
  PVector getFishRotation(){
    
    PVector fishDeltaPos = getDeltaPos();
    
    if(prevDirectionLerped != null){
      
      prevDirectionLerped = PVector.lerp(prevDirectionLerped, fishDeltaPos, 0.01);
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
    
    if(intentionality > 0){
      return new PVector(
        lerp(noiseX, deltaFood.x, intentionality),
        lerp(noiseY, deltaFood.y, intentionality),
        lerp(noiseZ, deltaFood.z, intentionality)
        );
    }
    else{
      return new PVector(
        lerp(noiseX, -deltaFood.x, abs(intentionality)),
        lerp(noiseY, -deltaFood.y, abs(intentionality)),
        lerp(noiseZ, -deltaFood.z, abs(intentionality))
        );
    }

  }
  
  
  float adjustSpeed(){
    
    if(gameManager.hasFish == false){
      
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
    else{
      return stepSizeWhenHooked; 
    } 
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
