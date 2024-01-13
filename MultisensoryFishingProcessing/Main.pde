import java.util.ArrayList;
import processing.serial.*; 


// ------------------------------------------------------------------------------------------------
//                                         NATIVE MAIN
// ------------------------------------------------------------------------------------------------


GameManager globalGameManager;
      //TODO rremove it is only for debug
      DebugSensoryInputModule globalDebugSensoryInputModule;

void setup() {
  background(99, 178, 240);
  //fullScreen(P3D);
  size(1400, 1400, P3D);
  hint(DISABLE_OPENGL_ERRORS);

  globalGameManager = new GameManager(this);
      //TODO rremove it is only for debug
      globalDebugSensoryInputModule = new DebugSensoryInputModule(globalGameManager); 
  globalGameManager.startExperience();
}

void draw() {
  globalGameManager.gameLoop(); 
      globalDebugSensoryInputModule.update();
}
      //TODO rremove it is only for debug
      void keyPressed(){
        globalDebugSensoryInputModule.OnkeyPressed(keyCode);
      }
      //TODO rremove it is only for debug
      void keyReleased() {
        globalDebugSensoryInputModule.OnkeyReleased(keyCode);
      }



// ------------------------------------------------------------------------------------------------
//                                      GAME MANAGER (MAIN MANAGER)
// ------------------------------------------------------------------------------------------------



// Implementazione della classe GameManager che eredita da AbstGameManager
class GameManager implements OutputModulesManager, InputModuleManager {
  
  // ------------------------------------------------------------------------------------------------
  //                                             PERSISTENCE 
  // ------------------------------------------------------------------------------------------------
  
  
  // ------------------------------------------- FINE-TUNABLES CONSTANTS -------------------------------------------  
  int NumFramesHaloExternUpdates = 5; 
  


  // ------------------------------------------- FIELDS -------------------------------------------
  boolean hasFish;
  float wireCountdown; // Conto alla rovescia del filo
  SessionData currentSession;
  ShakeDimention currentRodState;  
  GameState currentState; // Stato corrente del gioco
  GameState cachedState;
  int boxsize;
  int haloForWireRetrieving, haloForRawMovements, haloForShakeRodEvent;
  float cachedSpeedOfWireRetrieving;
  ShakeDimention cachedShakeRodEvent, prevCachedShakeRodEvent;
  RawMotionData cachedRawMotionData;
  
  
  // ------------------------------------------- DIPENDENCIES -------------------------------------------
  Fish fish;
  Player player;
  PApplet parent;
  CameraMovement cameraMovement;
  ArrayList<AbstSensoryOutModule> sensoryModules;
  SensoryInputModule sensoryInputModule = null;


  
  // ------------------------------------------- INTERFACE's GETTERS -------------------------------------------
  
  boolean isFishHooked(){
    return currentState == GameState.FishHooked;
  };
  PublicFish getFish(){
    return fish;
  }
  int getSizeOfAcquarium(){
    return boxsize;
  }
  
  PVector getCameraPosition(){
    return cameraMovement.getCameraPosition();
  }
  
  VerletNode[] getNodesOfWire(){
    return player.nodes;
  }
  
  
  // ------------------------------------------------------------------------------------------------
  //                                             CONSTRUCTOR 
  // ------------------------------------------------------------------------------------------------
  
  GameManager(PApplet _parent) {
    parent = _parent;
    currentState = GameState.Null; cachedState = GameState.Null;
    
    cameraMovement = new CameraMovement(this, parent);
    cameraMovement.TryConnectToFacePoseProvider();
        
    boxsize = (int)(min(width, height));// * 2 / 3; 
    
    player = new Player(this);
    fish = new Fish(this, player);
  }
  
  
  
  // ------------------------------------------------------------------------------------------------
  //                                             MAIN LOOP 
  // ------------------------------------------------------------------------------------------------
  
  // Usefull to understand the main logic
  void gameLoop(){
    
    updateState();
    
    if(currentState != GameState.StartExperience && currentState != GameState.End){
      background(85, 146, 200); // Colore azzurro per l'acqua        
    }
    else{
      background(99, 178, 240); 
    }
    
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
        if(player.HasHookedTheFish()){
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
  
  
  // ------------------------------------------------------------------------------------------------
  //                                           LIFE CYCLE 
  // ------------------------------------------------------------------------------------------------
  
  
  // ------------------------------------------- LIFE CYCLE ENTRY POINTS -------------------------------------------
  
  // Expose the entry points of the state machine that regulate the LIFE CYCLE of the application
  GameState manageGameStates(GameState preState, GameState newState) {
    switch (currentState) {
      
      case StartExperience:
        startExperience();
        
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
    }
    // Sovrascrivere se l'operazione produce un'alterazione del vincolo
    return newState;
  }
  
  
  // ------------------------------------------- EXECUTIONS ON STATE ACTIVATION -------------------------------------------
  
  // Start and Restart the application, so that the User can chose again the initial settings
  void startExperience(){
    
    sensoryModules = new ArrayList<AbstSensoryOutModule>();
    
    currentSession = new SessionData();
    //camera(width/2, height/2.0, 0, width/2, height/2, 0, 0, 1, 0);
    
    cachedState = GameState.StartExperience;
    updateState();
    
    createUI(globalGameManager);
  }
  
  // Method triggered after the User press Play on the UI, see the script WIMP_GUI.pde
  void StartGameWithSettings(PlayerInfo _playerInfo){
    
    //TODO Switch
    //if(sensoryInputModule == null) sensoryInputModule = new SensoryInputModule(this);
    sensoryInputModule = globalDebugSensoryInputModule;
   
    currentSession.playerInfo =_playerInfo;
    
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
  
  // Invoked at the start of each GamePlay, reset the game logic 
  void beginGameSession(){
    
    cachedRawMotionData = new RawMotionData();
    cachedSpeedOfWireRetrieving = 0;
    cachedShakeRodEvent = ShakeDimention.NONE; prevCachedShakeRodEvent = ShakeDimention.NONE;
    
    currentSession.ResetGameData();
        
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
    
    camera(width/2, height/2.0, 0, width/2, height/2, 0, 0, 1, 0);
    
    // TODO last edit to the values
    currentSession.sessionPerformanceValue = int(random(0, 2));
    currentSession.endTime = frameCount;
    
    println("Game Finished "+currentSession.endReason);
    
    writeCSVRow(currentSession); 
        
    createAnswerToContinuePlayingUI(currentSession.endReason == "FishCaught");
  }
  
  // Triggerd by the answer given to the GUI by the user see script:  WIMP_GUI.pde
  void AnswerToContinuePlaying(boolean value){
    if(value){
      setState(GameState.Begin);
    }
    else{
      setState(GameState.StartExperience);
    }
  }
  
  
  
  // ------------------------------------------- LIFE CYCLE UTILITY FUNCTIONS -------------------------------------------

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
  
  
  // ------------------------------------------------------------------------------------------------
  //                                 HANDLES FOR EXERNAL TRIGGERING EVENTS
  // ------------------------------------------------------------------------------------------------
  
  
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
  
};






// ------------------------------------------------------------------------------------------------
//                                 ENUMs & CLASS FOR GAME MANAGEMENT
// ------------------------------------------------------------------------------------------------
  

// Definizione dell'enumerazione per lo stato del gioco
enum GameState {
  Null, 
  StartExperience,
  Begin, 
  AttractingFish, 
  FishHooked,
  FishLost, 
  WireEnded,  
  End
}


class SessionData {
  public SessionData(){
    ResetGameData();
  }
  
  int startTime;
  int endTime;
  int sessionPerformanceValue;
  String dateTime = "";
  String endReason;
  PlayerInfo playerInfo;
  
  public void ResetGameData(){
    sessionPerformanceValue = 0;
    startTime = frameCount;
    endReason = "";
    dateTime = day()+"/"+month()+"/"+year()+" - "+hour()+"h:"+minute()+"min";
  }
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
