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
  SessionData currentSession;
  ShakeDimention currentRodState;
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
  ShakeDimention cachedShakeRodEvent = ShakeDimention.NONE, prevCachedShakeRodEvent = ShakeDimention.NONE;
  RawMotionData cachedRawMotionData = new RawMotionData();
  boolean hasFish;
  
  ArrayList<AbstSensoryOutModule> sensoryModules = new ArrayList<AbstSensoryOutModule>();
  SensoryInputModule sensoryInputModule;
  
  boolean isFishHooked(){
    return currentState == GameState.FishHooked;
  };
  PublicFish getFish(){
    return fish;
  }
  

  // Costruttore per GameManager
  GameManager() {
        
    boxsize = (int)(min(width, height)*0.85);// * 2 / 3; 
    
    totalWeightedScore = 0.0;
    totalWeightedScoreCount = 0;
    
    player = new Player(this);
    fish = new Fish(this, player);
    
    summativeEndReasons = "";
    
    currentState = GameState.Null;
  }
  
  void gameLoop(){
    
    updateState();
    
    if(currentState != GameState.AttractingFish && currentState != GameState.FishHooked){
      return;
    }
    
    fish.UpdatePosition();
    
    hint(ENABLE_DEPTH_SORT);
    
    if(haloForShakeRodEvent > 0){
      currentRodState = cachedShakeRodEvent;
      for (AbstSensoryOutModule sensoryModule : sensoryModules) {
        if(prevCachedShakeRodEvent != ShakeDimention.NONE && cachedShakeRodEvent != ShakeDimention.NONE){
          sensoryModule.OnShakeOfRod(ShakeDimention.NONE); 
        }
        sensoryModule.OnShakeOfRod(cachedShakeRodEvent); 
      }
      haloForShakeRodEvent = 0;
      
      if(currentState == GameState.AttractingFish && currentRodState == ShakeDimention.STRONG_HOOKING){
        if(player.hasHookedTheFish()){
           setState(GameState.FishHooked);
        }
      }
    }
    
    fish.UpdateIntentionality(currentRodState);
    
    RodStatusData data = calculateRodStatusData();
        
    player.TornWireOnRodMovments(data.rawMotionData);
    
    player.update();

    for (AbstSensoryOutModule sensoryModule : sensoryModules) {

      sensoryModule.OnRodStatusReading(data);
    }
    
    hint(DISABLE_DEPTH_SORT);
  }
  
  
  // Metodo per avviare la sessione di gioco
  void StartGameWithSettings(PlayerInfo _playerInfo){
    
    //TODO Switch
    //sensoryInputModule = new SensoryInputModule(this);
    sensoryInputModule = globalDebugSensoryInputModule;
    
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
    
    cachedState = GameState.Begin;
    updateState();
  }
  
  void beginGameSession(){
    wireCountdown = 1000.0;
    
    haloForWireRetrieving = NumFramesHaloExternUpdates;
    haloForRawMovements = NumFramesHaloExternUpdates;
    haloForShakeRodEvent = NumFramesHaloExternUpdates;
    
    currentRodState = ShakeDimention.NONE;
    
    hasFish = false;
    
    player.Restart();
    
    fish.Restart();
    
    setState(GameState.AttractingFish);
  }

  // Metodo per impostare lo stato del gioco
  void setState(GameState newState) {
    cachedState = newState;
  }
  void updateState(){
    if (currentState != cachedState) {
      GameState pre = currentState;
      currentState = cachedState;
      currentState = manageGameStates(pre, cachedState);
      
      // notify the modules of a relevant change in state
      if(cachedState == GameState.FishHooked || cachedState == GameState.FishLost || cachedState == GameState.WireEnded){
        for (AbstSensoryOutModule sensoryModule : sensoryModules) {
          switch (currentState) {
            case FishHooked:
              sensoryModule.OnFishHooked();
              break;
            case FishLost:
              sensoryModule.OnFishLost();
              break;
            case WireEnded:
              if(hasFish){
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
  
  void OnWireEnded(){
    setState(GameState.WireEnded);
  }
  
  void OnWireBreaks(){
    if(isFishHooked()){
      setState(GameState.FishLost);
    }
  }
  
  void OnFishTasteBait(){
     for (AbstSensoryOutModule sensoryModule : sensoryModules) {
       sensoryModule.OnFishTasteBait();
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
      
      
      newData.coefficentOfWireTension = player.UpdateWireRetreival(newData.speedOfWireRetrieving);
 
      
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
      
        // TODO Remove this is only for debug purposes
        //setState(GameState.FishLost);
        break;
        
      case FishHooked:
        hasFish = true;
        
        // TODO Remove this is only for debug purposes
        //setState(GameState.FishLost);
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
        if(hasFish){
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
    
    println("Game Finished "+currentSession.endReason);
    
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
    if(cachedShakeRodEvent != type){
      prevCachedShakeRodEvent = cachedShakeRodEvent;
      cachedShakeRodEvent = type;
      haloForShakeRodEvent = 1;
    }
  }
  
  void OnWeelActivated(float speedOfWireRetrieving){
    cachedSpeedOfWireRetrieving = speedOfWireRetrieving;
    haloForWireRetrieving = NumFramesHaloExternUpdates;
  }
  
  void OnRawMotionDetected(RawMotionData data){
    cachedRawMotionData = data;
    haloForRawMovements = NumFramesHaloExternUpdates;
  }
  
  VerletNode[] getNodesOfWire(){
    return player.nodes;
  }
};


GameManager globalGameManager;
DebugSensoryInputModule globalDebugSensoryInputModule;
Player player;
GameState currentState = GameState.Null; // Stato corrente del gioco
GameState cachedState = GameState.Null;

void setup() {
  background(99, 178, 240);
  fullScreen(P3D);
  //size(1400, 1400, P3D);
  //hint(ENABLE_DEPTH_SORT);
  hint(DISABLE_OPENGL_ERRORS);
  globalGameManager = new GameManager();
  
  //TODO rremove it is only for debug
  globalDebugSensoryInputModule = new DebugSensoryInputModule(globalGameManager);
  
  player = new Player(globalGameManager);
  
  createUI(globalGameManager);
  //TODO Remove and decomment createUI, just for debug
  //globalGameManager.StartGameWithSettings(new PlayerInfo("testplayer", new boolean[] {true, true, true}));
}

void draw() {
 
  if(currentState != GameState.Null && currentState != GameState.EndExperience){
    
      background(85, 146, 200); // Colore azzurro per l'acqua  
      globalGameManager.gameLoop();
  }
  else{
    background(99, 178, 240);
  }
  
  globalDebugSensoryInputModule.update();
}

void keyPressed(){
  globalDebugSensoryInputModule.OnkeyPressed(keyCode);
}
void keyReleased() {
  globalDebugSensoryInputModule.OnkeyReleased(keyCode);
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
