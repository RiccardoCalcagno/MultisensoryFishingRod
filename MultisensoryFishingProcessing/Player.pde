import java.util.ArrayList;
// Dichiarazione della classe Player
class Player {
  
  // ------------------------------------------------------------------------------------------------
  //                                             PERSISTENCE 
  // ------------------------------------------------------------------------------------------------
  
  
  // ------------------------------------------- FINE-TUNABLES CONSTANTS -------------------------------------------  
  
  //max damage supported by the wire
  float maxDamage = 50;
  
  // Bigger => More the wire should bounce in the moment in wich the fish touch it
  float multipliyerOfCollisionReaction = 3;
 
  // Gravitational force in 3D
  PVector weightOfNode = new PVector(0, 0.8, 0); 
  PVector weightOfBait = new PVector(0, 48, 0); 
  
  // This should define the lenght of the rope, not the position of the hook, this would stay evrytime almost in the middel of the boundingBox
  int totalNodes = 100; // 200
  
  // This is a constant force that is appplied to the origin of the wire (top extream of it) in order to make it reace a default position if the user is not applying other forces by moving the phiscal rod
  float speedToReachTheIdleOrigin = 0.1;
  
  // this is a coefficent to be fineTuned in order to intensify or decrese the force of the movements of the phisical rod, need to be adjusted in order not to make the hook be throunw out of the water
  float intensityOfRodMovments = 10000;
  
  // if the mouth of the fish is more distant form the food than minDistanceOfMouthFromFoodToHook at the moment of the Strong_Hooking shake than the hook do not success.
  int minDistanceOfMouthFromFoodToHook = 20;
  
  // Average the periods in which the fish is pushing the wire it is repeditly biting (just a taste actually) the hook, 
  // but with a minimum delay between each bites, namely this value. Expect a random variance of +- 0.2*numLoopsBetweenBites
  // This value increase with the intentionality of the fish map(intentionality, 0, 0.8, maxNumLoopsBetweenBites, minNumLoopsBetweenBites)
  int maxNumLoopsBetweenBites = 120;  int minNumLoopsBetweenBites = 80;
  
  // Dial this one to require to the user more or less reactivness to the fish tasting
  int numLoopsForReactivness = 17;   // they start from this value and each time the user fail to strinke this value increase of 4 untill numLoopsForReactivness * 3
  
  // quantity of wire retreived at each step
  float maxSpeedOfWireRetreiving = 2;
  
  // when the wire is idle which is the offset of the bait from the center of the room? (it should be a little bit below so that there is more wire to be retreived)
  float YoffsetOfBaitFromCenterOfRoom = 30;
  
  
  // ------------------------------------------- FIELDS -------------------------------------------  
  
  int counterOfLoopsBetweenPushes;
  int counterOfLoopsBetweenBites;
  int counterForReactivness;
  int numOfLoopsBetweenPushes = 5;
  float wireFishTention;
  int boxsize;
  float damageCounter;
  VerletNode[] nodes;
  float nodeDistance = 15;
  float wireCountdown;
  RawMotionData cachedRawMotionData = new RawMotionData();
  int timeSinceHooking;
  int countDownForCapturingAnimation;
  float timeSpentLookingUp;
  float timespentLookingDown;
  PVector speedRod;
  float lastWireTention;
  int lastFrameSinceAccellerationRodRead;
  int currentnumLoopsForReactivness;
  
  
  
  // ------------------------------------------- DEPENDENCIES -------------------------------------------  
    
  GameManager gameManager; // Manager del gioco
  Fish fish = null;
  
  
  // ------------------------------------------- INTERFACE's GETTERS -------------------------------------------
    
  PVector getHookPos(){
    return nodes[nodes.length -1].position.copy();
  }
  float wireLengthWhenIdle(){ 
    //We need to consider the gravity force that is streatching a little bit the wire
    return totalNodes * nodeDistance * 1 + 40;
  }
  
  PVector wireDirection(){   
    return PVector.sub(nodes[nodes.length/2].position, nodes[0].position).normalize();
  }

  PVector getOrigin(){
    float offsetAfterHooking = 0;
    if(timeSinceHooking > 0 && frameCount - timeSinceHooking < 100){
       offsetAfterHooking = map(frameCount - timeSinceHooking, 0, 100, 0, boxsize/4);
    }
    else if(gameManager.isFishHooked()){
      offsetAfterHooking = boxsize/4;
    }
    float _wireLengthWhenIdle = wireLengthWhenIdle();
    
    return new PVector (0, - _wireLengthWhenIdle + YoffsetOfBaitFromCenterOfRoom - wireCountdown + offsetAfterHooking, 0);
  }
  
  
  // ------------------------------------------------------------------------------------------------
  //                                             CONSTRUCTOR 
  // ------------------------------------------------------------------------------------------------

  // Costruttore per Player
  Player(GameManager _gameManager) {
    
    gameManager = _gameManager;
    
    boxsize = gameManager.getSizeOfAcquarium();
    // Inizializzazione delle variabili del giocatore
  }
  
  
  // ------------------------------------------------------------------------------------------------
  //                                             LIFE CYCLE 
  // ------------------------------------------------------------------------------------------------
  
  void Restart(){
    
    
      currentnumLoopsForReactivness = numLoopsForReactivness;
      
      speedRod = new PVector();
      lastFrameSinceAccellerationRodRead = frameCount;
      
      wireCountdown = 0;
      lastWireTention = 0;
      
      countDownForCapturingAnimation = -1;
    
      nodes = new VerletNode[totalNodes];
      
      PVector pos = getOrigin();
      for (int i = 0; i < totalNodes; i++) {
        nodes[i] = new VerletNode(pos);
        pos.y += nodeDistance;
      }
    
     wireCountdown = 0;
    
     damageCounter = maxDamage;
     
     wireFishTention = 0;
     
     timeSinceHooking = -1;
     
     counterOfLoopsBetweenBites = maxNumLoopsBetweenBites;
     counterForReactivness =-1;
     
     timeSpentLookingUp=0;
     timespentLookingDown=0;
  }


  PVector NegotiateFishShift(PVector fishDesiredDelta){
   
    //if(wireFishTention >0){
    if(fish != null && gameManager.isFishHooked() == true){
      PVector fishDistance = PVector.sub(nodes[0].position, fish.getPos());
      float wireDistanceIdle = wireLengthWhenIdle();
      if(fishDistance.magSq() > wireDistanceIdle*wireDistanceIdle){
        PVector wire_direction = wireDirection();
        PVector projectionToWireDirection = PVector.mult(wire_direction, PVector.dot(fishDesiredDelta, wire_direction) / wire_direction.magSq());
        PVector secondComponent = PVector.sub(fishDesiredDelta, projectionToWireDirection);  
        
        fishDistance.setMag(fishDistance.mag() - wireDistanceIdle);
        fishDistance.add(secondComponent);
        
        return PVector.sub(fishDistance, fishDesiredDelta);
      }
    }
    return new PVector(0,0,0);
  }
      
      
  // Metodo per simulare l'evento di ritrazione del filo
  float UpdateWireRetreival(float speedOfWireRetrieving) {
    
    speedOfWireRetrieving = constrain(map(speedOfWireRetrieving, -0.77, 0.77, -1, 1), -1, 1);
    
    if(countDownForCapturingAnimation > 0){
      wireCountdown += maxSpeedOfWireRetreiving * 10;
      countDownForCapturingAnimation-=1;
      return 0.1;
    }
    else if(countDownForCapturingAnimation == 0){
      gameManager.OnWireEnded();
      return 0;
    }
    
    
    wireFishTention = 0;
    float speedLimit = 1;
    if(gameManager.isFishHooked() == true){
      
      float coeffOfTentionBasedOnFishDirection = PVector.angleBetween(wireDirection(), fish.getDeltaPos()) / PI;
      
      
      if(coeffOfTentionBasedOnFishDirection > 0.5){
        timeSpentLookingUp+=1;
      }
      else{
        timespentLookingDown+=1;
      }
      float percentageOfTimePulling = 0.5;
      if(timespentLookingDown+timeSpentLookingUp > 100){
        percentageOfTimePulling = timespentLookingDown / (timespentLookingDown+timeSpentLookingUp);
      }
      
        
      if( PVector.dist(nodes[0].position, fish.getPos()) >=  wireLengthWhenIdle()){
  
        if(speedOfWireRetrieving < 0.5){
               
          if(speedOfWireRetrieving - coeffOfTentionBasedOnFishDirection < 0){  // it means that even that there was a wire giving out it was not compensating enough
          
          if(speedOfWireRetrieving<0 && coeffOfTentionBasedOnFishDirection> 0.5){
            speedLimit = map(coeffOfTentionBasedOnFishDirection, 0.5, 1, 1, 0.7);
          }
          
          wireFishTention = constrain( -(speedOfWireRetrieving - coeffOfTentionBasedOnFishDirection)/2.0, 0, 1); // the max value for speedOfWireRetrieving - coeffOfTentionBasedOnFishDirection is -2
          }       
        }
        
        if(speedOfWireRetrieving > 0){
          float weight = map(wireFishTention, 0, 1, 1, 0.5);
          if(percentageOfTimePulling > 0.6){
            weight*= map(percentageOfTimePulling, 0.6, 0.8, 1.5, 2);
          }
          gameManager.SetGameEventForScoring(GameEvent.Good_LeavingWireWhileTention_Shade, weight);
        }
      }
      
      // The fish might give to much spiky pulls
      wireFishTention = lerp(wireFishTention, lastWireTention, 0.7);
      lastWireTention = wireFishTention;
        
    
      if(wireFishTention > 0.1 && speedOfWireRetrieving < 0){
        
        float weight = map(wireFishTention, 0.1, 1, 0.5, 1);
        gameManager.SetGameEventForScoring(GameEvent.WireInTention_Shade, weight);
        
        damageCounter -= wireFishTention;
        
        if(damageCounter < 0){
          gameManager.OnWireBreaks();
        }
      }
    }
    
    float ammountOfWireRetreived = -speedOfWireRetrieving * maxSpeedOfWireRetreiving * speedLimit;
    
    wireCountdown += ammountOfWireRetreived;
    if(YoffsetOfBaitFromCenterOfRoom - wireCountdown > boxsize/2 + VisualSensoryModule.verticalPaddingOfVisualBox){
      wireCountdown =  YoffsetOfBaitFromCenterOfRoom - boxsize/2 - VisualSensoryModule.verticalPaddingOfVisualBox;
    }
    
    if(gameManager.debugUtility.debugLevels.get(DebugType.ConsoleIntentionAndTension) == true && (abs(speedOfWireRetrieving)>0.001 || wireFishTention > 0)){
      gameManager.debugUtility.Println("Tention: "+nf(wireFishTention, 2, 3)+",  WireRetreived: "+nf(ammountOfWireRetreived, 2, 2)+", missingWire: "+nf((YoffsetOfBaitFromCenterOfRoom - wireCountdown +boxsize /2), 1, 2)+", damageCounter: "+nf(damageCounter, 10, 1), true);      
    }
    
    if (YoffsetOfBaitFromCenterOfRoom - wireCountdown < -boxsize /2) {
      countDownForCapturingAnimation = 140;
    }
    
    return wireFishTention;
  }
  
  
  
  void TornWireOnRodMovments(RawMotionData rawMotionData){
    cachedRawMotionData = rawMotionData;
  }
  
  void update(){
    if(fish == null){
     fish = gameManager.fish; 
    }
    
    counterOfLoopsBetweenPushes--; 
    counterOfLoopsBetweenBites--;
    counterForReactivness--;
    
    
    if(gameManager.isFishHooked() == false && counterOfLoopsBetweenBites <= 0 && counterOfLoopsBetweenPushes > 0){
      BiteTheHook();
    }
    
    applyForcesOfRod();
    
    if(gameManager.isFishHooked() == false){
      handleCollision();
    }
    
    applyPhisics();
    
    // Lazy application of all the forces collected during the cicle
    for (VerletNode node : nodes) {
      node.applyCachedForces();
    }
    
    float rigidityOfRod = totalNodes * 2;
    // More iterations define the rigidity of the rope
    for(int i=0; i<rigidityOfRod; i++){
      for (int j = 0; j < nodes.length; j++) { // TODO REMOVE 
        nodes[j].applyConstrains((j< nodes.length-1)? nodes[j + 1]: null, nodeDistance, (float)(i+1) / (float)rigidityOfRod);
        
        if( i ==  rigidityOfRod-1){
          nodes[j].position.x = lerp(nodes[j].position.x, 0, 0.003);
          nodes[j].position.z = lerp(nodes[j].position.z, 0, 0.003);
        }
      }
    }
  }
  
  void applyForcesOfRod(){
    
     // Force that will guide the hook slowly towards the idle origin, in order to not make the hook disappear if the user pull too much the rod.
     nodes[0].cacheTarget(getOrigin(), (countDownForCapturingAnimation == -1)? speedToReachTheIdleOrigin: 1);
     
     var mouth = fish.getPos();
     
     if(gameManager.isFishHooked() == true){
        nodes[nodes.length -1].cacheTarget(mouth, 0.6);
     }
     else if(counterForReactivness > 0){
         float intensityOfPushToTheMouth = constrain((1 - (abs(currentnumLoopsForReactivness/2 - counterForReactivness) * 2 / currentnumLoopsForReactivness) )*3, 0, 1) * 0.01;
         nodes[nodes.length -1].cacheTarget(mouth, intensityOfPushToTheMouth);
     }else if(counterForReactivness == 0){
         var dir = new Vec3(fish.getFishRotation());
         var forceOfPush = 4* weightOfBait.y;
         dir.setMag(forceOfPush);
         dir.rotateX(random(0, PI/10));
         dir.rotateY(random(0, PI/10));
         dir.rotateZ(random(0, PI/10));
         nodes[nodes.length -1].cacheForce(dir);
       }
     
    
    PVector accelleration = getAccellerationInScene(cachedRawMotionData, gameManager.isRightHanded);
    float multiplier = -((frameCount - lastFrameSinceAccellerationRodRead) / frameRate) * intensityOfRodMovments;
    lastFrameSinceAccellerationRodRead = frameCount;
    speedRod.add(PVector.mult(accelleration, multiplier));  
    
    speedRod = PVector.lerp(speedRod, new PVector(), 0.05);
    
    nodes[0].cacheForce(speedRod);
  }
  
  void handleCollision() {
    float mouthRadius = PublicFish.fishHeight / 4;
    PVector fishPos = fish.getPos(); 
    PVector fishRotation = fish.getFishRotation();
    
    PVector mouthPos = PVector.sub(fishPos, fishRotation.copy().setMag(mouthRadius));

    for (int i = 0; i < nodes.length; i++) {
      VerletNode node = nodes[i];
   
      float distance = PVector.dist(node.position, mouthPos);
      
      if((i == nodes.length -1) & (distance < mouthRadius*1.3)){
        counterOfLoopsBetweenPushes = numOfLoopsBetweenPushes;
      }
        
      if (distance < mouthRadius) {
        // Calcola il vettore di spostamento per spostare la corda in base alla collisione
        PVector collisionNormal = PVector.sub(node.position, mouthPos).normalize();
        PVector collisionForce = collisionNormal.mult((mouthRadius - distance) * multipliyerOfCollisionReaction);
        
        // Applica la forza della collisione alla corda
        node.cacheForce(collisionForce);
      }
    }
  }
  
  
  boolean HasHookedTheFish(){
    
    if(counterForReactivness > 0){
      
      if( PVector.dist(fish.getPos(),nodes[nodes.length - 1].position) < minDistanceOfMouthFromFoodToHook){
        timeSinceHooking = frameCount;
        return true;
      }
    }
    
    gameManager.SetGameEventForScoring(GameEvent.UserDidNotAnsweredToFishBite);
    if(currentnumLoopsForReactivness < numLoopsForReactivness*3){
      currentnumLoopsForReactivness = currentnumLoopsForReactivness + 4; 
    }
    return false;
  }
  
  
  void BiteTheHook(){
    gameManager.SetGameEventForScoring(GameEvent.TheFishTastedTheBait);
    counterForReactivness = currentnumLoopsForReactivness;        
    counterOfLoopsBetweenBites = int( map(fish.getIntentionality(), 0, 0.8, maxNumLoopsBetweenBites, minNumLoopsBetweenBites) * random(0.8, 1.2));
    gameManager.OnFishTasteBait();
  }
    
  void applyPhisics() {
    for (int i = 1; i < nodes.length; i++) {
      VerletNode node = nodes[i];
      
      // Add Innertia
      node.cacheForce(PVector.sub(node.position, node.oldPosition));
      
      // Add gravity force
      node.cacheForce( ((i >= nodes.length -1)? weightOfBait: weightOfNode));
    }
  }
}
