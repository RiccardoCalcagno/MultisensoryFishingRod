import java.util.ArrayList;
// Dichiarazione della classe Player
class Player {
  
  // ------------------------------------------------------------------------------------------------
  //                                             PERSISTENCE 
  // ------------------------------------------------------------------------------------------------
  
  
  // ------------------------------------------- FINE-TUNABLES CONSTANTS -------------------------------------------  
  
  //max damage supported by the wire
  int maxDamage = 2000;//200;
  
  // Bigger => More the wire should bounce in the moment in wich the fish touch it
  float multipliyerOfCollisionReaction = 3;
 
  // Gravitational force in 3D
  PVector gravity = new PVector(0, 0.4, 0); 
  
  // This should define the lenght of the rope, not the position of the hook, this would stay evrytime almost in the middel of the boundingBox
  int totalNodes = 200;
  
  // This is a constant force that is appplied to the origin of the wire (top extream of it) in order to make it reace a default position if the user is not applying other forces by moving the phiscal rod
  float speedToReachTheIdleOrigin = 0.1;
  
  // this is a coefficent to be fineTuned in order to intensify or decrese the force of the movements of the phisical rod, need to be adjusted in order not to make the hook be throunw out of the water
  float intensityOfRodMovments = 800;
  
  // This is how much the pulling forces produced by the movement of the phisical rod should deviate from the vertical (Y) axis. (with some noise)
  float intensityOfRandomVariationsFormTheYAxisInRodPulling = 0.5;
  
  // Average the periods in which the fish is pushing the wire it is repeditly biting (just a taste actually) the hook, 
  // but with a minimum delay between each bites, namely this value. Expect a random variance of +- 0.2*numLoopsBetweenBites
  int numLoopsBetweenBites = 50;
  
  // Dial this one to require to the user more or less reactivness to the fish tasting
  int numOfLoopsBetweenPushes = 5;
  
  // if 1 => 1 goodShake = 1 catch, if 0 => 1 goodShake = 0 catch, in between => 1 goodShake = randomWithProbabilityOf(rarenessOfHooking) catch
  float rarenessOfHooking = 0.8;
  
  // quantity of wire retreived at each step
  float maxSpeedOfWireRetreiving = 0.8;
  
  // when the wire is idle which is the offset of the bait from the center of the room? (it should be a little bit below so that there is more wire to be retreived)
  float YoffsetOfBaitFromCenterOfRoom = 30;
  
  
  // ------------------------------------------- FIELDS -------------------------------------------  
  
  int counterOfLoopsBetweenPushes;
  int counterOfLoopsBetweenBites;
  float wireFishTention;
  int boxsize;
  float damageCounter;
  VerletNode[] nodes;
  float nodeDistance = 15;
  float wireCountdown;
  RawMotionData cachedRawMotionData = new RawMotionData();
  int timeSinceHooking;
  int countDownForCapturingAnimation;
  
  
  // ------------------------------------------- DEPENDENCIES -------------------------------------------  
    
  GameManager gameManager; // Manager del gioco
  PublicFish fish = null;
  
  
  // ------------------------------------------- INTERFACE's GETTERS -------------------------------------------
    
  PVector getHookPos(){
    return nodes[nodes.length -1].position.copy();
  }
  float wireLengthWhenIdle(){
    //We need to consider the gravity force that is streatching a little bit the wire
    return totalNodes * nodeDistance * 1;
  }
  
  PVector wireDirection(){
    return PVector.sub(getHookPos(), nodes[0].position).normalize();
  }

  PVector getOrigin(){
    float offsetAfterHooking = 0;
    if(timeSinceHooking > 0 && frameCount - timeSinceHooking < 100){
       offsetAfterHooking = map(frameCount - timeSinceHooking, 0, 100, 0, boxsize/4);
    }
    else if(gameManager.isFishHooked()){
      offsetAfterHooking = boxsize/4;
    }
    return new PVector (0, - wireLengthWhenIdle() + YoffsetOfBaitFromCenterOfRoom - wireCountdown + offsetAfterHooking, 0);
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
    
      wireCountdown = 0;
      
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
     
     counterOfLoopsBetweenBites = numLoopsBetweenBites;
  }


  PVector NegotiateFishShift(PVector fishDesiredDelta){
   
    if(wireFishTention >0){
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
    
    
    if(countDownForCapturingAnimation > 0){
      wireCountdown += maxSpeedOfWireRetreiving * 15;
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
      
      if( PVector.dist(nodes[0].position, fish.getPos()) >=  wireLengthWhenIdle() && speedOfWireRetrieving < 0.5){
        float coeffOfTentionBasedOnFishDirection = PVector.angleBetween(wireDirection(), fish.getDeltaPos()) / PI;
        if(speedOfWireRetrieving - coeffOfTentionBasedOnFishDirection < 0){  // it means that even that there was a wire giving out it was not compensating enough
        
        if(speedOfWireRetrieving<0 && coeffOfTentionBasedOnFishDirection> 0.5){
          speedLimit = map(coeffOfTentionBasedOnFishDirection, 0.5, 1, 1, 0.7);
        }
        
        wireFishTention = -(speedOfWireRetrieving - coeffOfTentionBasedOnFishDirection)/2.0; // the max value for speedOfWireRetrieving - coeffOfTentionBasedOnFishDirection is -2
        }       
      }
    }
    
    if(wireFishTention > 0.1){
      damageCounter -= wireFishTention;
      
      if(damageCounter < 0){
        gameManager.OnWireBreaks();
      }
    }
    
    float ammountOfWireRetreived = -speedOfWireRetrieving * maxSpeedOfWireRetreiving * speedLimit;
    
    wireCountdown += ammountOfWireRetreived;
    
    if(abs(speedOfWireRetrieving)>0.001 || wireFishTention > 0){
      println("WireRetreived: "+nf(ammountOfWireRetreived, 2, 2)+" missingWire: "+nf((YoffsetOfBaitFromCenterOfRoom - wireCountdown +boxsize /2), 1, 2)+"damageCounter: "+nf(damageCounter, 10, 1));      
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
     fish = gameManager.getFish(); 
    }
    
    counterOfLoopsBetweenPushes--; 
    counterOfLoopsBetweenBites--;
    
    if(gameManager.isFishHooked() == false && counterOfLoopsBetweenBites == 0 && counterOfLoopsBetweenPushes > 0){
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
      for (int j = 0; j < nodes.length; j++) {
        nodes[j].applyConstrains((j< nodes.length-1)? nodes[j + 1]: null, nodeDistance, (float)(i+1) / (float)rigidityOfRod);
      }
    }
  }
  
  void applyForcesOfRod(){
    
     // Force that will guide the hook slowly towards the idle origin, in order to not make the hook disappear if the user pull too much the rod.
     nodes[0].cacheTarget(getOrigin(), (countDownForCapturingAnimation == -1)? speedToReachTheIdleOrigin: 1);
     
     
     if(gameManager.isFishHooked() == true){
        nodes[nodes.length -1].cacheTarget(fish.getPos(), 0.6);
     }
     
     // Force simulated by the motion of the rod
     if(abs(cachedRawMotionData.speed) > 0.1){
       Vec3 rodPullingVector = new Vec3(0, -cachedRawMotionData.speed*intensityOfRodMovments, 0);
       
       rodPullingVector.rotateX(map(noise(frameCount * 0.01), 0, 1, -intensityOfRandomVariationsFormTheYAxisInRodPulling, intensityOfRandomVariationsFormTheYAxisInRodPulling)); 
       rodPullingVector.rotateY(map(noise((frameCount+ 1000) * 0.01), 0, 1, -intensityOfRandomVariationsFormTheYAxisInRodPulling, intensityOfRandomVariationsFormTheYAxisInRodPulling)); 
       nodes[0].cacheForce(rodPullingVector); 
     }
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
        
        if(counterOfLoopsBetweenBites < 0){
          BiteTheHook();
        }
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
    
    if(counterOfLoopsBetweenBites >= 0){
      
      if(random(0, 1) <= rarenessOfHooking){
        timeSinceHooking = frameCount;
        return true;
      }
    }
    return false;
  }
  
  
  void BiteTheHook(){
    counterOfLoopsBetweenBites = int(numLoopsBetweenBites * random(0.8, 1.2));
    gameManager.OnFishTasteBait();
  }
    
  void applyPhisics() {
    for (int i = 1; i < nodes.length; i++) {
      VerletNode node = nodes[i];
      
      // Add Innertia
      node.cacheForce(PVector.sub(node.position, node.oldPosition));
      
      // Add gravity force
      node.cacheForce( ((i >= nodes.length -1)? gravity.copy().mult(60): gravity));
    }
  }
}
