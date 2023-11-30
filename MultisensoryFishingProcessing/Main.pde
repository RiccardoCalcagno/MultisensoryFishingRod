import java.util.ArrayList;


// Dichiarazione di una classe astratta per il GameManager
interface WIMPUIManager {
  void handleWireCountdown(int value);
  
  void StartGameWithSettings(PlayerInfo playerInfo);
  
  void AnswerToContinuePlaying(boolean value);
}

// Definizione dell'enumerazione per lo stato del gioco
enum GameState {
  Null,
  Begin, 
  ColdAttractingFish, 
  HotAttractingFish,
  FishNibbing, 
  FishHooked, 
  FishOpposingForce, 
  FishLost, 
  WireEnded, 
  FishCaught, 
  End,
  EndExperience
}

class SessionData {
  float sessionPerformanceWeight;
  int sessionPerformanceValue;
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
  int wireCountdown; // Conto alla rovescia del filo
  GameState currentState; // Stato corrente del gioco
  SessionData currentSession;
  float totalWeightedScore; // Punteggio totale ponderato
  int totalWeightedScoreCount; // Contatore per il punteggio totale
  Fish fish;
  Player player;

  int NumFramesHaloExternUpdates = 5;
  int haloForWireRetrieving, haloForRawMovements;
  float cachedSpeedOfWireRetrieving = 0;
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
    haloForWireRetrieving = NumFramesHaloExternUpdates;
    haloForRawMovements = NumFramesHaloExternUpdates;
    
    totalWeightedScore = 0.0;
    totalWeightedScoreCount = 0;
    
    player = new Player(this);
    fish = new Fish();
    
    sensoryInputModule = new SensoryInputModule(this);
    
    currentState = GameState.Null;
  }
  

  
  
  void OnShakeEvent(ShakeDimention type){
    for (AbstSensoryOutModule sensoryModule : sensoryModules) {
        sensoryModule.OnShakeOfRod(type);
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
  
  void OnWireBreaks(){
  
  }
  
  void gameLoop(){
    
    background(255);
    
    fish.UpdatePosition();
    
    RodStatusData data = calculateRodStatusData();
    for (AbstSensoryOutModule sensoryModule : sensoryModules) {

      sensoryModule.OnRodStatusReading(data);
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
        float coeffOfTentionBasedOnFishDirection = minAngleBetweenVectors(player.wireDirection, fish.getDeltaPos()) / PI;
        float coeffForRetreivingTheWire = (1 -newData.speedOfWireRetrieving) / 2.0;
        
        newData.coefficentOfWireTension = coeffOfTentionBasedOnFishDirection * coeffForRetreivingTheWire;
      }
      
      if(newData.coefficentOfWireTension > 0.2){
        player.damageWire(newData.coefficentOfWireTension);
      }
      
      haloForWireRetrieving--;
      haloForRawMovements--;
    
      return newData;
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
    // Inizializzare i gestori e la sessione di gioco
    // Esempio: inizializzare Player, Fish, sistema di punteggio, ecc.
  }

  // Metodo per gestire il conto alla rovescia del filo
  void handleWireCountdown(int valueFromEvent) {
    wireCountdown -= valueFromEvent;
    if (wireCountdown <= 0) {
      // Transizione allo stato di End quando il conto alla rovescia del filo raggiunge 0
      setState(GameState.WireEnded);
    }
  }

  // Metodo per impostare lo stato del gioco
  void setState(GameState newState) {
    if (currentState != newState) {
      GameState pre = currentState;
      currentState = newState;
      currentState = manageGameStates(pre, newState);
    }
  }

  // Metodo per gestire gli stati del gioco e le transizioni
  GameState manageGameStates(GameState preState, GameState newState) {
    switch (currentState) {
      case Begin:
        beginGameSession();
        break;

      case ColdAttractingFish:
        // Logica per lo stato ColdAttractingFish
        break;

      // Implementare la logica per gli altri stati allo stesso modo

      case End:
        // Logica per terminare la sessione di gioco
        endGameSession();
        break;
      case EndExperience:
        EndExperience();
        break;
    }
    // Sovrascrivere se l'operazione produce un'alterazione del vincolo
    return newState;
  }
  
  void beginGameSession(){
    wireCountdown = 1000;
  }

  // Metodo per terminare la sessione di gioco
  void endGameSession() {
    
    // last edit to the values
    currentSession.sessionPerformanceWeight = random(0.0, 1.0);
    currentSession.sessionPerformanceValue = int(random(0, 2));
  
    float weightedScore = currentSession.sessionPerformanceValue * currentSession.sessionPerformanceWeight;
    totalWeightedScore += weightedScore;
    totalWeightedScoreCount++;
    
    createAnswerToContinuePlayingUI();
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
    
    writeCSVRow(currentSession.playerInfo.playerName, score, totalWeightedScoreCount, selectedModalities[0], selectedModalities[1], selectedModalities[2]);
    
  }
};


GameManager globalGameManager;
Player player;

void setup() {
  size(1400, 1400, P3D);
  globalGameManager = new GameManager();
  player = new Player(globalGameManager);
  
  createUI(globalGameManager);
}

void draw() {
  background(135, 206, 250); // Colore azzurro per l'acqua
  
  if(globalGameManager.currentState != GameState.Null && globalGameManager.currentState != GameState.EndExperience){
      globalGameManager.gameLoop();
  }
}







//   ------------------------- Utilities -----------------------------

float minAngleBetweenVectors(float[] v1, float[] v2) {
  // Calcolo del prodotto scalare tra i due vettori
  float dotProduct = dotProduct(v1, v2);
  
  // Calcolo delle magnitudini dei due vettori
  float magV1 = magnitude(v1);
  float magV2 = magnitude(v2);
  
  // Calcolo del coseno dell'angolo tra i due vettori
  float cosAngle = dotProduct / (magV1 * magV2);
  
  // Calcolo dell'angolo in radianti
  float angle = acos(cosAngle);
  
  return angle;
}

// Funzione per calcolare il prodotto scalare tra due vettori
float dotProduct(float[] v1, float[] v2) {
  return v1[0] * v2[0] + v1[1] * v2[1] + v1[2] * v2[2];
}

// Funzione per calcolare la magnitudine di un vettore
float magnitude(float[] v) {
  return sqrt(v[0] * v[0] + v[1] * v[1] + v[2] * v[2]);
}
