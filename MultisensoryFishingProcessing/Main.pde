import java.util.ArrayList;


// Dichiarazione di una classe astratta per il GameManager
interface WIMPUIManager {
  
  void StartGameWithSettings(PlayerInfo playerInfo);
  
  void AnswerToContinuePlaying(boolean value);
}

// Definizione dell'enumerazione per lo stato del gioco
enum GameState {
  Null, 
  Begin, 
  AttractingFish, 
  FishHooked, 
  FishOpposingForce, 
  FishLost, 
  WireEnded,  
  End, 
  EndExperience 
}

class SessionData {
  float sessionPerformanceWeight;
  int sessionPerformanceValue;
  String endReason;
  PlayerInfo playerInfo;
}
// Classe per memorizzare le informazioni del giocatore
class PlayerInfo {
  String playerName;
  boolean[] selectedModalities;
  PlayerInfo(String name, boolean[] modalities) {
    playerName = name;
    selectedModalities = modalities;
  }
}


// Implementazione della classe GameManager che eredita da AbstGameManager
class GameManager implements WIMPUIManager, OutputModulesManager, InputModuleManager {
  float wireCountdown; // Conto alla rovescia del filo
  GameState currentState; // Stato corrente del gioco
  SessionData currentSession;
  float totalWeightedScore; // Punteggio totale ponderato
  int totalWeightedScoreCount; // Contatore per il punteggio totale
  int boxsize;
  String summativeEndReasons;
  Fish fish;
  Player player;
  int getSizeOfAcquarium(){
    return boxsize;
  }

  int NumFramesHaloExternUpdates = 5;
  int haloForWireRetrieving, haloForRawMovements, haloForShakeRodEvent;
  float cachedSpeedOfWireRetrieving = 0;
  ShakeDimention cachedShakeRodEvent = ShakeDimention.NONE;
  RawMotionData cachedRawMotionData = new RawMotionData();
  
  ArrayList<AbstSensoryOutModule> sensoryModules = new ArrayList<AbstSensoryOutModule>();
  SensoryInputModule sensoryInputModule;
  
  boolean isFishHooked(){
    return currentState == GameState.FishHooked || currentState == GameState.FishOpposingForce;
  };
  PublicFish getFish(){
    return fish;
  }
  

  // Costruttore per GameManager
  GameManager() {
    
    boxsize = min(width, height) * 2 / 3; 
    
    totalWeightedScore = 0.0;
    totalWeightedScoreCount = 0;
    
    player = new Player(this);
    fish = new Fish(this, player);
    
    summativeEndReasons = "";
    
    sensoryInputModule = new SensoryInputModule(this);
    
    currentState = GameState.Null;
  }
  
  void gameLoop(){
    
    player.update();
    
    fish.UpdatePosition();
    
    hint(ENABLE_DEPTH_SORT);
    
    if(haloForShakeRodEvent <= 0){
      for (AbstSensoryOutModule sensoryModule : sensoryModules) {
        sensoryModule.OnShakeOfRod(cachedShakeRodEvent); 
      }
      cachedShakeRodEvent = ShakeDimention.NONE;
      haloForWireRetrieving = 0;
    }
    
    RodStatusData data = calculateRodStatusData();
    for (AbstSensoryOutModule sensoryModule : sensoryModules) {

      sensoryModule.OnRodStatusReading(data);
    }
    
    player.render();
    
    hint(DISABLE_DEPTH_SORT);
  }
  
  

  // Metodo per avviare la sessione di gioco
  void StartGameWithSettings(PlayerInfo _playerInfo){
    currentSession = new SessionData();
    currentSession.playerInfo = _playerInfo;
    for(int i=0; i<3; i++){
      if(_playerInfo.selectedModalities[i]){
        AbstSensoryOutModule moduleToAdd = null; 
        switch (i) {
          case 0:
            moduleToAdd = new VisualSensoryModule(this);
            break;          
          case 1:
            moduleToAdd = new AudioSensoryModule(this);
            break;
          case 2:
            moduleToAdd = new HapticSensoryModule(this);
            break;
        }
        sensoryModules.add(moduleToAdd);
      }
    }
    
    setState(GameState.Begin);
  }
  
  void beginGameSession(){
    wireCountdown = 1000.0;
    
    haloForWireRetrieving = NumFramesHaloExternUpdates;
    haloForRawMovements = NumFramesHaloExternUpdates;
    haloForShakeRodEvent = NumFramesHaloExternUpdates;
    
    player.Restart();
    
    fish.Restart();
    
    setState(GameState.AttractingFish);
  }

  // Metodo per impostare lo stato del gioco
  void setState(GameState newState) {
    if (currentState != newState) {
      GameState pre = currentState;
      currentState = newState;
      currentState = manageGameStates(pre, newState);
      
      // notify the modules of a relevant change in state
      if(newState == GameState.FishHooked || newState == GameState.FishLost || newState == GameState.WireEnded){
        for (AbstSensoryOutModule sensoryModule : sensoryModules) {
          switch (currentState) {
            case FishHooked:
              sensoryModule.OnFishHooked();
              break;
            case FishLost:
              sensoryModule.OnFishLost();
              break;
            case WireEnded:
              if(player.hasFish()){
                sensoryModule.OnFishCaught();
              }
              else{
                sensoryModule.OnWireEndedWithNoFish();
              }
              break;
          }
        }
      }
    }
  }
  
  void OnWireBreaks(){
    if(isFishHooked()){
      setState(GameState.FishLost);
    }
  }
  
  RodStatusData calculateRodStatusData(){
      
      if(haloForWireRetrieving <= 0){
        cachedSpeedOfWireRetrieving = 0;
      }
      if(haloForRawMovements <= 0){
        cachedRawMotionData = new RawMotionData();
      }
    
      RodStatusData newData = new RodStatusData();
      
      newData.speedOfWireRetrieving = cachedSpeedOfWireRetrieving;
      newData.rawMotionData = cachedRawMotionData;
      
      if(isFishHooked() == false){
        newData.coefficentOfWireTension = 0;
      }
      else{
        float coeffOfTentionBasedOnFishDirection = PVector.angleBetween(player.getWireDirection(), fish.getDeltaPos()) / PI;
        float coeffForRetreivingTheWire = (1 - newData.speedOfWireRetrieving) / 2.0;
        
        newData.coefficentOfWireTension = coeffOfTentionBasedOnFishDirection * coeffForRetreivingTheWire;
      }
      
      if(newData.coefficentOfWireTension > 0.2){
        player.damageWire(newData.coefficentOfWireTension);
      }
      
      wireCountdown -= newData.speedOfWireRetrieving;
      if (wireCountdown <= 0) {
        setState(GameState.WireEnded);
      }
      
      haloForWireRetrieving--;
      haloForRawMovements--;
    
      return newData;
  }


  // Metodo per gestire gli stati del gioco e le transizioni
  GameState manageGameStates(GameState preState, GameState newState) {
    switch (currentState) {
      case Begin:
        beginGameSession();
        break;

      case AttractingFish:
        break;
        
      case FishHooked:
        break;
   
      case FishLost:
      case WireEnded:
        OnReasonToEnd(currentState);
        break;
        
      case End:
        endGameSession();
        break;
        
      case EndExperience:
        EndExperience();
        break;
    }
    // Sovrascrivere se l'operazione produce un'alterazione del vincolo
    return newState;
  }
  
  void OnReasonToEnd(GameState reason){
    
    switch(reason){
      case FishLost: currentSession.endReason = "FishLost";
        break;
      case WireEnded: 
        if(player.hasFish()){
           currentSession.endReason = "FishCaught";
        }
        else{
           currentSession.endReason = "WireEndedWithoutFish"; 
        }
        break;
    }  
    
    setState(GameState.End);
  }

  // Metodo per terminare la sessione di gioco
  void endGameSession() {
    
    // TODO last edit to the values
    currentSession.sessionPerformanceWeight = random(0.0, 1.0);
    currentSession.sessionPerformanceValue = int(random(0, 2));
  
    float weightedScore = currentSession.sessionPerformanceValue * currentSession.sessionPerformanceWeight;
    totalWeightedScore += weightedScore;
    totalWeightedScoreCount++;
    
    summativeEndReasons += currentSession.endReason+" ";
    
    createAnswerToContinuePlayingUI(currentSession.endReason == "FishCaught");
  }
  
  void AnswerToContinuePlaying(boolean value){
    if(value){
      setState(GameState.Begin);
    }
    else{
      setState(GameState.EndExperience);
    }
  }
  
  void EndExperience() {
    float score;
    if (totalWeightedScoreCount == 0) {
      score = 0.0; // Se non ci sono dati, restituisci 0
    } else {
      score = totalWeightedScore / totalWeightedScoreCount; // Calcola la media ponderata
    }
    summativeEndReasons = summativeEndReasons.substring(0, summativeEndReasons.length() -1);
    writeCSVRow(currentSession.playerInfo.playerName, score, totalWeightedScoreCount, selectedModalities[0], selectedModalities[1], selectedModalities[2], summativeEndReasons);
    
  }
  
  
  void OnShakeEvent(ShakeDimention type){
        cachedShakeRodEvent = type;
        haloForShakeRodEvent = NumFramesHaloExternUpdates;
  }
  
  void OnWeelActivated(float speedOfWireRetrieving){
    cachedSpeedOfWireRetrieving = speedOfWireRetrieving;
    haloForWireRetrieving = NumFramesHaloExternUpdates;
  }
  
  void OnRawMotionDetected(RawMotionData data){
    cachedRawMotionData = data;
    haloForRawMovements = NumFramesHaloExternUpdates;
  }
};


GameManager globalGameManager;
Player player;

void setup() {
  size(1400, 1400, P3D);
  //hint(ENABLE_DEPTH_SORT);
  hint(DISABLE_OPENGL_ERRORS);
  globalGameManager = new GameManager();
  player = new Player(globalGameManager);
  
  //createUI(globalGameManager);
  //TODO Remove and decomment createUI, just for debug
  globalGameManager.StartGameWithSettings(new PlayerInfo("testplayer", new boolean[] {true, true, true}));
}

void draw() {
  
  if(globalGameManager.currentState != GameState.Null && globalGameManager.currentState != GameState.EndExperience){
    
      background(85, 146, 200); // Colore azzurro per l'acqua  
      globalGameManager.gameLoop();
  }
  else{
    background(255); 
  }
}







//   ------------------------- Utilities -----------------------------


PImage getWithAlpha(PImage in, float alpha) {
  PImage out = in.get();
  for (int i=0; i<out.pixels.length; i++) {
    color c = out.pixels[i];
    float r = red(c);
    float g = green(c);
    float b = blue(c);
    out.pixels[i] = color(r,g,b, alpha);
  }
  return out;
}



// Classe di potenziamento di PVector, per le rotazioni in 3D
class Vec3 extends PVector {

  Vec3() { super(); }
  Vec3(float x, float y) { super(x, y); }
  Vec3(float x, float y, float z) { super(x, y, z); }
  Vec3(PVector v) { super(); set(v); }

  String toString() {
    return String.format("[ %+.2f, %+.2f, %+.2f ]",
      x, y, z);
  }

  PVector rotate(float angle) {
    return rotateZ(angle);
  }

  PVector rotateX(float angle) {
    float cosa = cos(angle);
    float sina = sin(angle);
    float tempy = y;
    y = cosa * y - sina * z;
    z = cosa * z + sina * tempy;
    return this;
  }

  PVector rotateY(float angle) {
    float cosa = cos(angle);
    float sina = sin(angle);
    float tempz = z;
    z = cosa * z - sina * x;
    x = cosa * x + sina * tempz;
    return this;
  }

  PVector rotateZ(float angle) {
    float cosa = cos(angle);
    float sina = sin(angle);
    float tempx = x;
    x = cosa * x - sina * y;
    y = cosa * y + sina * tempx;
    return this;
  }
  
  PMatrix3D lookAt(PVector target) {
     return lookAt(target, new PVector(0.0, 1.0, 0.0), new PMatrix3D());
   }

   PMatrix3D lookAt(PVector target, PVector up) {
     return lookAt(target, up, new PMatrix3D());
   }

   PMatrix3D lookAt(PVector target, PMatrix3D out) {
      return lookAt(target, new PVector(0.0, 1.0, 0.0), out);
    }

   PMatrix3D lookAt(PVector target, PVector up, PMatrix3D out) {
    PVector k = PVector.sub(target, this);
    float m = k.magSq();
    if(m < EPSILON) {
      return out;
    }
    k.mult(1.0 / sqrt(m));

    PVector i = new PVector();
    PVector.cross(up, k, i);
    i.normalize();

    PVector j = new PVector();
    PVector.cross(k, i, j);
    j.normalize();

    out.set(i.x, j.x, k.x, 0.0,
      i.y, j.y, k.y, 0.0,
      i.z, j.z, k.z, 0.0,
      0.0, 0.0, 0.0, 1.0);
    return out;
  }
}
