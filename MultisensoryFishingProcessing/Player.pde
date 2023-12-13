import java.util.ArrayList;
// Dichiarazione della classe Player
class Player {
  
  float multipliyerOfCollisionReaction = 4;
  float stepTime = 0.01;
  PVector gravity = new PVector(0, 0.098, 0); // Gravitational force in 3D
  int totalNodes = 50;
  float speedToReachTheIdleOrigin = 10;
  float intensityOfRodMovments = 10;
  float intensityOfRandomVariationsFormTheYAxisInRodPulling = 0.005;
  
  GameManager gameManager; // Manager del gioco
  PImage foodImg;
  int boxsize;
  float damageCounter;
  float actualThetaY, actualThetaZ;
  VerletNode[] nodes;
  float nodeDistance = 15;
  PVector origin;
  float scaleScene;
  PublicFish fish = null;
  boolean hasFish;
  RawMotionData cachedRawMotionData = new RawMotionData();
  
  float ropeLenght(){
    return  nodeDistance * totalNodes;
  }
  PVector getHookPos(){
    return nodes[nodes.length -1].position.copy();
  }
  PVector getWireDirection(){
    return PVector.sub(getHookPos(), nodes[0].position).normalize();
  }
  
  boolean hasFish(){
    return hasFish; 
  }
 

  // Costruttore per Player
  Player(GameManager _gameManager) {
    
    foodImg = loadImage("food.png");
    foodImg.resize(40, 60);
    
    gameManager = _gameManager;
    
    boxsize = gameManager.getSizeOfAcquarium();
    scaleScene = (2.0 +(float)boxsize / (float)min(width, height)) / 3.0;
    
    nodes = new VerletNode[totalNodes];
    
    origin = new PVector (0, - ropeLenght() + 90, 0); // Posizione del punto di ancoraggio (soffitto)
    
    PVector pos = origin.copy();
    for (int i = 0; i < totalNodes; i++) {
      nodes[i] = new VerletNode(pos);
      pos.y += nodeDistance;
    }
    // Inizializzazione delle variabili del giocatore
  }
  
  void Restart(){
    
     damageCounter = 100;
     
     hasFish = false;
  }

  // Metodo per simulare l'evento di ritrazione del filo
  void damageWire(float value) {
    damageCounter -= value;
    
    if(damageCounter < 0){
      gameManager.OnWireBreaks();
    }
  }
  
  void TornWireOnRodMovments(RawMotionData rawMotionData){
    cachedRawMotionData = rawMotionData;
  }
  
  void update(){
    if(fish == null){
     fish = gameManager.getFish(); 
    }
    
    applyForcesOfRod();
    
    handleCollision();
    
    applyPhisics();
    
    // Lazy application of all the forces collected during the cicle
    for (VerletNode node : nodes) {
      node.applyCachedForces();
    }
    
    // More iterations define the rigidity of the rope
    for(int i=0; i<totalNodes * 2; i++){
      applyConstraints();
    }
  }
  
  void applyForcesOfRod(){
    
     // Force that will guide the hook slowly towards the idle origin, in order to not make the hook disappear if the user pull too much the rod.
     PVector towardsTheIdle = PVector.sub(origin.copy(), nodes[0].position).setMag(speedToReachTheIdleOrigin);
     nodes[0].cacheForce(towardsTheIdle);
     
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
      
      if (distance < mouthRadius) {
        // Calcola il vettore di spostamento per spostare la corda in base alla collisione
        PVector collisionNormal = PVector.sub(node.position, mouthPos).normalize();
        PVector collisionForce = collisionNormal.mult((mouthRadius - distance) * multipliyerOfCollisionReaction);
        
        // Applica la forza della collisione alla corda
        node.cacheForce(collisionForce);
      }
    }
  }
    
  void applyPhisics() {
    for (int i = 1; i < nodes.length; i++) {
      VerletNode node = nodes[i];
      
      // Add Innertia
      node.cacheForce(PVector.sub(node.position, node.oldPosition));
      
      // Add gravity force
      node.cacheForce( ((i >= nodes.length -1)? gravity.copy().mult(20): gravity));
    }
  }
  
  void applyConstraints() {
    for (int i = 0; i < nodes.length - 1; i++) {
      VerletNode node1 = nodes[i];
      VerletNode node2 = nodes[i + 1];
  
      float dist = PVector.dist(node1.position, node2.position);
      float difference = 0;
      if (dist > 0) { 
        difference = (nodeDistance - dist) / dist;
      }
      float assimmetryCoeff = 0.5;//map(i, 0, nodes.length - 2, 0.1, 0.5);
      PVector translateGeneric = PVector.sub(node1.position, node2.position).mult(assimmetryCoeff * difference);
      node1.position.add(translateGeneric);
      node2.position.sub(translateGeneric);
    }
  }
  
  void render() {
    pushMatrix();
    scale(scaleScene);
    translate(width/2, height/2, 0);
    hint(ENABLE_STROKE_PURE);
    for (int i = 0; i < nodes.length - 1; i++) {
      if(nodes[i].position.y < -boxsize/2){
       stroke(150); 
      }
      else{
        stroke(0);
      }
      line(nodes[i].position.x, nodes[i].position.y, nodes[i].position.z,
           nodes[i+1].position.x, nodes[i+1].position.y, nodes[i+1].position.z);
    }
    hint(DISABLE_STROKE_PURE);
    
    popMatrix();
    
    pushMatrix();
    scale(scaleScene);
    PVector hookPos = getHookPos();
    translate(width/2 + hookPos.x, height/2 + hookPos.y, hookPos.z);
    
    PVector directionLasts = PVector.sub(hookPos, nodes[totalNodes -2].position);
    
    float thetaY = atan2(directionLasts.x, directionLasts.z) - PI/2;
    float thetaX = atan2(-directionLasts.y, sqrt(directionLasts.z * directionLasts.z + directionLasts.x * directionLasts.x));
    float thetaZ = atan2(directionLasts.y, directionLasts.x);
    
    actualThetaY = lerp(actualThetaY, thetaY, 0.05);
    actualThetaZ = lerp(actualThetaZ, thetaZ, 0.05);
    
    rotateY(actualThetaY);
    rotateX(-PI);
    rotateZ(actualThetaZ);
    
    fill(0);
    imageMode(CENTER);
    image(foodImg, -20, 0); 
    popMatrix();
  }
}



class VerletNode {
  PVector position;
  PVector oldPosition;
  ArrayList<PVector> lazyForcesToApply = new ArrayList<PVector>();
  
  VerletNode(PVector startPos) {
    position = startPos.get();
    oldPosition = startPos.get();
  }
  
  void cacheForce(PVector force){
    lazyForcesToApply.add(force);
  }
  
  void applyCachedForces(){
    oldPosition = position.copy();
    for (PVector force : lazyForcesToApply) {
       position.add(force);
    }
    lazyForcesToApply.clear();
  }
  
  void updatePosition(PVector newPos) {
    oldPosition.set(position);
    position.set(newPos);
  }
}
