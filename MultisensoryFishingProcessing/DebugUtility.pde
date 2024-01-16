 
 enum DebugType{
   IOFile,
   FishMovement,
   InputAsKeyboard,
   ConsoleAll,
   ConsoleIntentionAndTension,
   
 }
 
 public class DebugUtility{
   
   public DebugSensoryInputModule globalDebugSensoryInputModule;
   public PApplet parent;
   
   public DebugUtility(PApplet _parent, GameManager gameManager, HashMap<DebugType, Boolean> _debugLevels){
     parent = _parent;
     debugLevels = _debugLevels;
     globalDebugSensoryInputModule = new DebugSensoryInputModule(gameManager); 
   }
   
   HashMap<DebugType, Boolean> debugLevels;
   
   HashMap<GameEvent, int[]> debuggingScoresDic;
   HashMap<GameEvent, Float> debuggingScoresSumWithWeight;
   HashMap<GameEvent, Integer> debuggingScoresSum;
   
   public void Draw(){
     globalDebugSensoryInputModule.update();
   }
   void OnkeyPressed(int keyPress){
     globalDebugSensoryInputModule.OnkeyPressed(keyPress);
   }
   void OnkeyReleased(int keyPress){
     globalDebugSensoryInputModule.OnkeyReleased(keyPress);
   }
   
   void Println(String text){
     if(debugLevels.get(DebugType.ConsoleAll) == true){
        println(text);
     }
   }
   
   void SetGameEventForScoring(GameEvent event, float contingentAlteration){
      int[] preValue = new int[]{};
      float preValueWeight = 0;
      int preValueSum = 0;
      if(debuggingScoresDic.containsKey(event) == true){
        preValue = debuggingScoresDic.get(event);
        preValueWeight = (float)debuggingScoresSumWithWeight.get(event);
        preValueSum = (int)debuggingScoresSum.get(event);
      }
      preValue = append(preValue, frameCount);
      debuggingScoresSumWithWeight.put(event, (Float)(preValueWeight + contingentAlteration));
      debuggingScoresSum.put(event, (Integer)(preValueSum+1));
      debuggingScoresDic.put(event, preValue);
   }
   
   public void Debug_PlotEventsInTime(SessionData currentSession, String writtenInFile){
      int max = -1;
      for (Map.Entry entry : debuggingScoresDic.entrySet()) {
              int[] value = debuggingScoresDic.get((GameEvent)entry.getKey());
              if(value.length > 0 && max < value[value.length -1]){
                max = value[value.length -1];
              }
      }
      int min = currentSession.startTime;
      
      String toFile = "###############################################################################################################################################\n New Game: "
      +writtenInFile+"\n###############################################################################################################################################\n";
      
      toFile+=Debug_PlotForOneEvent(GameEvent.CheckpointInContinuousGoodShakesPeriod_Shade, min, max);
      toFile+=Debug_PlotForOneEvent(GameEvent.AttractingShake, min, max);
      toFile+=Debug_PlotForOneEvent(GameEvent.ComplexAttractingShake, min, max);
      toFile+=Debug_PlotForOneEvent(GameEvent.BadScaringShake, min, max);
      toFile+=Debug_PlotForOneEvent(GameEvent.FishStartForgetting, min, max);
      toFile+="\n";
      toFile+=Debug_PlotForOneEvent(GameEvent.TheFishTastedTheBait, min, max);
      toFile+=Debug_PlotForOneEvent(GameEvent.UserDidNotAnsweredToFishBite, min, max);
      toFile+=Debug_PlotForOneEvent(GameEvent.NiceShakeItMightHaveCoughtIt, min, max);
      toFile+="\n";
      toFile+=Debug_PlotForOneEvent(GameEvent.WireInTention_Shade, min, max);
      toFile+=Debug_PlotForOneEvent(GameEvent.Good_LeavingWireWhileTention_Shade, min, max);
      toFile+="\n";
      
      if(debugLevels.get(DebugType.IOFile) == true){
        writeDebugEndGame(toFile);
      }
      else{
        Println(toFile);
      }
    }
    
    String Debug_PlotForOneEvent(GameEvent event, int min, int max){
      String toOutPut="\n"+event.toString()+", count:"+ debuggingScoresSum.get(event)+", with weight: "+debuggingScoresSumWithWeight.get(event)+", timeLine: \n";
      int[] times = debuggingScoresDic.get(event);
      if(times == null){
        times = new int[] {};
      }
      for(int i=0; i<times.length; i++){
        times[i] = int(map(times[i], min, max, 0, 219));
      }
      int[][] frequ = new int[220][3];
      int[] countA = new int[220];
      for(int i=0; i<220; i++){
        int count = 0;
        for(int j=0; j<times.length; j++){
          if(times[j] == i)
            count++;
        }
        countA[i] = count;
        int cent = int(count / 100);
        int dec = int( (count%100) / 10);
        int unit = count%10;
        frequ[i] = new int[] { cent, dec, unit};
      }
      
      for(int i=0; i<3; i++){
        String text = "";
        for(int j=0; j<220; j++){
          char carattere = '-';
          if(frequ[j][i] > 0 || countA[j] > 0){
            carattere = (char(frequ[j][i] + 48));
          }
          text+=carattere;
        }
        toOutPut+=text+"\n";
      }
      
      return toOutPut;
    } 
      
    void writeDebugEndGame(String text) {
      
      String filename = "DebugGames.txt";
      boolean fileExists = new File(dataPath(filename)).exists();
      
      try {
        PrintWriter csvWriter = new PrintWriter(new FileWriter(dataPath(filename), true));
    
        csvWriter.println(text);
        csvWriter.println("");
    
        csvWriter.flush();
        csvWriter.close();
        println("Riga scritta con successo in " + filename);
      } catch (IOException e) {
        println("Si è verificato un errore durante la scrittura del file CSV: " + e);
      }
    }

 }
 
 
 






class DebugSensoryInputModule extends SensoryInputModule{
  
  // Repetidly press one number between 1 an 7 (correspondent to the values of ShakeDimention) to trigger a burst of that kind of shake for all the time of the frequent digit
  HashMap<Integer, Boolean> keysPressed = new HashMap<Integer, Boolean>();

  boolean prevWasShake = false;
  //int lastPress = 0;
  //char lastChar = ' ';
  // use inputModuleManager to notify the game with all the data comming from the rod
  DebugSensoryInputModule(InputModuleManager _inputModuleManager){
    super(_inputModuleManager);
    for (int i = 0; i < 256; i++) {
      keysPressed.put(i, false);
    }
  }
  
  void update(){
    checkCombination();
    
    // Random movement for debug
    //var data = new RawMotionData(); data.speed = map(noise(frameCount * 0.1), 0, 1, -0.5, 0.5);
    //inputModuleManager.OnRawMotionDetected(data);
  }
  
  void OnkeyPressed(int keyPress){
   
    keysPressed.put(keyPress, true);
  }
  
  void OnkeyReleased(int keyPress){
    keysPressed.put(keyPress, false);
  }
  
  void checkCombination() {
    // Verifica la combinazione di tasti
    boolean ctrlPressed = keysPressed.get(17); // Codice tasto Ctrl
    
    if(ctrlPressed == true){
      
      if(prevWasShake){
        inputModuleManager.OnShakeEvent(ShakeDimention.NONE);
        prevWasShake = false;
      }
      for(int i = 49; i< 58; i++){
        if(keysPressed.get(i)){
          inputModuleManager.OnWeelActivated(map(i, 49, 57, -1, 1));
        }
      }
    }
    else{
      if(keysPressed.get(48)){
        inputModuleManager.OnShakeEvent(ShakeDimention.NONE); prevWasShake = false;
      }
      else if(keysPressed.get(49)){
        inputModuleManager.OnShakeEvent(ShakeDimention.SUBTLE);        prevWasShake = true;
      }
      else if(keysPressed.get(50)){
        inputModuleManager.OnShakeEvent(ShakeDimention.LITTLE_ATTRACTING);        prevWasShake = true;
      }
      else if(keysPressed.get(51)){
        inputModuleManager.OnShakeEvent(ShakeDimention.LONG_ATTRACTING);        prevWasShake = true;
      }
      else if(keysPressed.get(52)){
        inputModuleManager.OnShakeEvent(ShakeDimention.LITTLE_NOT_ATTRACTING);        prevWasShake = true;
      }
      else if(keysPressed.get(53)){
        inputModuleManager.OnShakeEvent(ShakeDimention.STRONG_HOOKING);        prevWasShake = true;
      }
      else if(keysPressed.get(54)){
        inputModuleManager.OnShakeEvent(ShakeDimention.STRONG_NOT_HOOKING);        prevWasShake = true;
      }
      else{
        if(prevWasShake){
          inputModuleManager.OnShakeEvent(ShakeDimention.NONE); prevWasShake = false;
        }
      }
    }
  }
  
  
}
