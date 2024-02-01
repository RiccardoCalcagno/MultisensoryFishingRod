
class Fish implements PublicFish{
  
  // ------------------------------------------------------------------------------------------------
  //                                             PERSISTENCE 
  // ------------------------------------------------------------------------------------------------
  
  
  // ------------------------------------------- FINE-TUNABLES CONSTANTS -------------------------------------------  
    
  // coefficent expressing how much the valence of a certain 
  // shake change the intentionality of the fish at each cicle
  float intensityOfValenceOfShakesForAttraction = 0.001;
  
  // Speed of the fish on free condition
  float stepSize = 2; 
  
  // Speed of the fish when hooked
  float stepSizeWhenHooked = 4;  
  
  // threshold distance necessary to shape the speed of the 
  // fish in it environment, with food vision
  float distanceFromFoodWhenStartToDecellerate = 50;
  
  // reaching this value with the counter: 
  // timeSinceAttractionWasPositive define the maximum extream 
  // of intentionality unlocked. [Needs to be a multiple of 5]
  int strinkingTimeToReachOptimumAttractability = 500; 
  
  // If no shake is introduced since this ammount of frames, 
  // the intentionality of the fish start reaching the 0 with 
  // a certain speed (Forgetting)
  int numFramesAfterFishstartForgetting = 300;
  
  // Speed of forgetting his intentionality
  float speedOfForgettingIntentionality = 0.002;
  
  // this express a value of intentionality to reach the bottom
  // of the see when the fish is hooked
  float intentionToGoDownWhenHooked = 0.24; 
  
  // set this values to adjust the degree in wich a certain 
  // shake is attracting - scaring the fish , intentionality 
  // can go from -0.3 to 0.8
  public void setShakeAttractionMapping(){
    shakesValenceForAttracting.set("NONE", 0);
    shakesValenceForAttracting.set("LITTLE_ATTRACTING", 0.5);    
    shakesValenceForAttracting.set("LONG_ATTRACTING", 1);  
    shakesValenceForAttracting.set("STRONG_HOOKING", -5);  
    shakesValenceForAttracting.set("STRONG_NOT_HOOKING", -4); 
  }
  
  
  // ------------------------------------------- FIELDS -------------------------------------------  
  
  int timeSinceAttractionWasPositive; //timeSinceAttractionWasPositive indicate the number of cicle of positive attraction not interrupted by any episodes of negative attraction
  int timeOfLastInfluencingShake; // Usefull To introduce the forgetting parameter of the fish
  FloatDict shakesValenceForAttracting = new FloatDict();
  PVector prevPos, pos, prevDirectionLerped = null;
  float actualThetaX, actualThetaY, actualThetaZ;
  int boxsize;
  float intentionality; // Intentionality of the fish (0 to 1)
  PVector direction = new PVector();
  PVector fishShift = new PVector();

  
  // ------------------------------------------- FDEPENDENCIES -------------------------------------------  
    
  GameManager gameManager;
  Player player;
  
  
  // ------------------------------------------- INTERFACE's GETTERS -------------------------------------------
  
  PVector getPos(){
    return pos.copy();
  }
  PVector getDeltaPos(){
    return direction.copy().add(fishShift);
  }
  float getIntentionality(){
    return intentionality;
  }
  
  PVector getFishRotation(){

    PVector fishDeltaPos = direction.copy();
    
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
  
  
  // ------------------------------------------------------------------------------------------------
  //                                             CONSTRUCTOR 
  // ------------------------------------------------------------------------------------------------
  
  
  Fish(GameManager _gameManager, Player _player) {
    
    setShakeAttractionMapping();
    gameManager = _gameManager;
    player = _player;
     
    boxsize = gameManager.getSizeOfAcquarium();
  }
  
  
  
  // ------------------------------------------------------------------------------------------------
  //                                             LIFE CICLE 
  // ------------------------------------------------------------------------------------------------
  
  
  void Restart(){
   
    pos = new PVector(random(-boxsize/2, boxsize/2), random(-boxsize/2, boxsize/2), random(-boxsize/2, boxsize/2));
    
    timeSinceAttractionWasPositive = 0;
    timeOfLastInfluencingShake = 0;
    
    intentionality = 0;
  }
  
  
  void UpdatePosition() {
    
    float speed = 0; 
    
    if(gameManager.debugUtility.debugLevels.get(DebugType.FishMovement) == true){
      direction = calculateDeltaTarget(); 
      speed = adjustSpeed();    
    }
 
    direction.setMag(speed);
    
    fishShift = player.NegotiateFishShift(direction);
    
    pos.add(PVector.add(direction, fishShift));
    
    // Constrain fish within the cube
    pos.x = constrain(pos.x, -boxsize/2, boxsize/2);
    if(player.countDownForCapturingAnimation == -1){
      pos.y = constrain(pos.y, -boxsize/2, boxsize/2);
    }
    pos.z = constrain(pos.z, -boxsize/2, boxsize/2);
    
    //DebugHeadColliderAndSpeedVector();
  }
  
  void UpdateIntentionality(ShakeDimention currentShake){
    
    // The fish when at the hook move frenetically and randomly
    if(gameManager.isFishHooked()){
      intentionality = 0;
      return;
    }
    
    switch(currentShake){
     case LITTLE_ATTRACTING:
       gameManager.SetGameEventForScoring(GameEvent.AttractingShake);
       break;
     case LONG_ATTRACTING:
       gameManager.SetGameEventForScoring(GameEvent.ComplexAttractingShake);
       break;
     case STRONG_HOOKING:
     case STRONG_NOT_HOOKING:
       gameManager.SetGameEventForScoring(GameEvent.BadScaringShake);
       break;
     case NONE:
       break;
    }
    
    // Each type of shake as a valence (a weight) that put in comparison (good-bad) the shakes together, 
    // then intensityOfValenceOfShakesForAttraction is necessary to fine tuning all the intensity based on how much we want the intentionality to be responsive
    float valenceOfShake = shakesValenceForAttracting.get(currentShake.toString()) * intensityOfValenceOfShakesForAttraction;
  
    if(valenceOfShake > 0){
      if(intentionality > 0){
        valenceOfShake = map(intentionality, 0, 0.8, valenceOfShake, 0);
      }
    }
    else{
      valenceOfShake = map(intentionality, -0.3, 0.8, 0, valenceOfShake);
    }
    
    gameManager.debugUtility.currentDeltaOFIntentionality = valenceOfShake;
          
    if(valenceOfShake != 0){

      intentionality += valenceOfShake;
      
      if(valenceOfShake < 0){
        timeSinceAttractionWasPositive = 0;
      }
      else if(timeSinceAttractionWasPositive < strinkingTimeToReachOptimumAttractability){
        
        timeSinceAttractionWasPositive++;
        float wieight = map(int(timeSinceAttractionWasPositive / int(strinkingTimeToReachOptimumAttractability / 5)), 2.0, 5.0, 0.0, 1.0);
        if(wieight > 0.1){
          gameManager.SetGameEventForScoring(GameEvent.CheckpointInContinuousGoodShakesPeriod_Shade, wieight);
        }
      }
      timeOfLastInfluencingShake = frameCount;
    }
    
    // Fish is progressively forgetting about its past intentionality if the hook is not more highlighted by any shake of the rod
    if(frameCount - timeOfLastInfluencingShake > numFramesAfterFishstartForgetting){
       gameManager.SetGameEventForScoring(GameEvent.FishStartForgetting);
       intentionality = lerp(intentionality, 0, speedOfForgettingIntentionality);
    }
    
    // The intentionality can grow till a bigger upper limit of the user is doing the correct movments for a longer time, 
    // while as soon as he make a mistake the upper limit decrease immediately to its lowest, this because the fish got scared
    float upperEndOfIntentionality = map(timeSinceAttractionWasPositive, 0, strinkingTimeToReachOptimumAttractability, 0.4, 0.8);
    
    intentionality = constrain(intentionality, -0.3, upperEndOfIntentionality);
        
    // Debug
    if(gameManager.debugUtility.debugLevels.get(DebugType.ConsoleIntentionAndTension) == true && ( abs(valenceOfShake)>0.0001 || frameCount - timeOfLastInfluencingShake > numFramesAfterFishstartForgetting)){
      gameManager.debugUtility.Println("Intent: "+nf(intentionality, 1, 2)+" in [-0.3, "+nf(upperEndOfIntentionality, 1, 2)+"]", true);      
    }
  }

  
  PVector calculateDeltaTarget(){
    float targetIntentionality = intentionality;
    PVector deltaFood = new PVector();
    if(gameManager.isFishHooked() == false){
      calculateDeltaFood(deltaFood);
    }
    else{
      deltaFood = new PVector(0,1,0); // tendency to stay in the bottom during the capturing
      var intentionToGoDown = intentionToGoDownWhenHooked;
      var time = (frameCount - gameManager.currentSession.startTime) / frameRate;
      if(time > 150 && time < 200){
        intentionToGoDown = map(time, 150, 200, intentionToGoDown, 0);
      }
      targetIntentionality = (pos.y < 0) ? intentionToGoDownWhenHooked: map(pos.y, boxsize/2, 0, 0, intentionToGoDownWhenHooked);
    }
    
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
    
    if(targetIntentionality > 0){
      return new PVector(
        lerp(noiseX, deltaFood.x, targetIntentionality),
        lerp(noiseY, deltaFood.y, targetIntentionality),
        lerp(noiseZ, deltaFood.z, targetIntentionality)
        );
    }
    else{
      return new PVector(
        lerp(noiseX, -deltaFood.x, abs(targetIntentionality)),
        lerp(noiseY, -deltaFood.y, abs(targetIntentionality)),
        lerp(noiseZ, -deltaFood.z, abs(targetIntentionality))
        );
    }

  }
  
  
  float adjustSpeed(){
    
    if(gameManager.isFishHooked() == false){
      
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
    
    // !!!ATTENTION!!!  Method extremely coupled with the module VisualSensoryModule, do not evolve it!
    
    float scaleScene =  (2.0 +(float)boxsize / (float)min(width, height)) / 3.0;
    PVector mouthPos = PVector.sub(pos, getFishRotation().setMag(PublicFish.fishHeight / 4));
    pushMatrix();
    scale(scaleScene);
    translate(width/2 + mouthPos.x, height/2 + mouthPos.y, mouthPos.z);
    stroke(color(255, 0, 0));
    sphere(PublicFish.fishHeight / 4);
    popMatrix();
    pushMatrix();
    scale(scaleScene);
    PVector enlargedDirection = direction.copy().mult(100);
    translate(width/2 + pos.x + enlargedDirection.x, height/2 + pos.y + enlargedDirection.y, pos.z + enlargedDirection.z);
    stroke(color(0, 255, 0));
    sphere(10);
    line(0,0,0, -enlargedDirection.x, -enlargedDirection.y, -enlargedDirection.z);
    popMatrix();
  }
}
