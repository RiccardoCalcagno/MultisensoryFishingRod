import g4p_controls.*;



String playerName = "";
boolean[] selectedModalities = new boolean[3]; // Array per memorizzare le modalità selezionate
GTextField playerNameField;
GCheckbox cbSight, cbAudition, cbHaptic;
GPanel panel = null;

GLabel questionLabel, endMessage;
GButton yesButton, noButton;
GPanel newPanel = null;
float scala = 1.5; 

GameManager manager;

void createUI(GameManager _manager) {
  
  manager = _manager;
  
  
  if(panel == null){
    panel = new GPanel(this, width/2 - 150* scala, height/2 - 150* scala, 300 * scala, 300 * scala);
    panel.setCollapsible(false);
    panel.setText("Multisensory Fishing");
    panel.setTextAlign(GAlign.CENTER, GAlign.MIDDLE);
  
    GLabel subTitle = new GLabel(this, 20 * scala, 30 * scala, 260 * scala, 40 * scala);
    subTitle.setText("Please enter your name and select multiple modalities.");
    subTitle.setTextAlign(GAlign.CENTER, GAlign.MIDDLE);
  
    playerNameField = new GTextField(this, 20 * scala, 80 * scala, 260 * scala, 30 * scala);
    playerNameField.setPromptText("Enter your name (max 50 characters)");
    playerNameField.setOpaque(true);
  
    cbSight = new GCheckbox(this, 40 * scala, 140 * scala, 100 * scala, 30 * scala);
    cbSight.setSelected(true);
    cbSight.setText("Sight");
    cbAudition = new GCheckbox(this, 40 * scala, 180 * scala, 100 * scala, 30 * scala);
    cbAudition.setSelected(true);
    cbAudition.setText("Audition");
    cbHaptic = new GCheckbox(this, 40 * scala, 220 * scala, 100 * scala, 30 * scala);
    cbHaptic.setSelected(true);
    cbHaptic.setText("Haptic");
  
    GButton playButton = new GButton(this, 100 * scala, 270 * scala, 100 * scala, 40 * scala);
    playButton.setText("PLAY");
   
    // Assegna azioni al pulsante PLAY
    playButton.addEventHandler(this, "onPlayButtonClick");
  
    // Aggiungi elementi al pannello
    panel.addControl(subTitle);
    panel.addControl(playerNameField);
    panel.addControl(cbSight);
    panel.addControl(cbAudition);
    panel.addControl(cbHaptic);
    panel.addControl(playButton);
  }
}


// Metodo chiamato quando il pulsante PLAY viene premuto
public void onPlayButtonClick(GButton source, GEvent event) {
  playerName = playerNameField.getText();
  selectedModalities[0] = cbSight.isSelected();
  selectedModalities[1] = cbAudition.isSelected();
  selectedModalities[2] = cbHaptic.isSelected();

  // Creazione di un oggetto per memorizzare le informazioni del giocatore
  PlayerInfo playerInfo = new PlayerInfo(playerName, selectedModalities);
  
  // Esempio di utilizzo delle informazioni memorizzate
  println("Player Name: " + playerInfo.playerName);
  println("Selected Modalities: " + playerInfo.selectedModalities);
  
  disposeUI();
  
  manager.StartGameWithSettings(playerInfo);
}

void disposeUI() {
  playerNameField.dispose();
  cbSight.dispose();
  cbAudition.dispose();
  cbHaptic.dispose();
  panel.dispose();
  
  panel = null;
}



void createAnswerToContinuePlayingUI(boolean haveWon) {
    
  if(newPanel == null){
    newPanel = new GPanel(this, width/2 - 150* scala, height/2 - 100* scala, 300 * scala, 200 * scala);
    newPanel.setCollapsible(false);
    newPanel.setText("Continue?");
    newPanel.setTextAlign(GAlign.CENTER, GAlign.MIDDLE);
  
    endMessage = new GLabel(this, 20 * scala, 25 * scala, 260 * scala, 40 * scala);
    if(haveWon){
      endMessage.setText("YOU HAVE WON!");
    }
    else{
      endMessage.setText("Unfortunately you have lost ;(");
    }
    endMessage.setTextAlign(GAlign.CENTER, GAlign.MIDDLE);
  
    questionLabel = new GLabel(this, 20 * scala, 50 * scala, 260 * scala, 40 * scala);
    questionLabel.setText("Would you like to continue playing with the same settings?");
    questionLabel.setTextAlign(GAlign.CENTER, GAlign.MIDDLE);
  
    yesButton = new GButton(this, 50 * scala, 100 * scala, 80 * scala, 40 * scala);
    yesButton.setText("Yes");
    yesButton.addEventHandler(this, "onYesButtonClick");
  
    noButton = new GButton(this, 170 * scala, 100 * scala, 80 * scala, 40 * scala);
    noButton.setText("No");
    noButton.addEventHandler(this, "onNoButtonClick");
  
    newPanel.addControl(endMessage);
    newPanel.addControl(questionLabel);
    newPanel.addControl(yesButton);
    newPanel.addControl(noButton);
  }
}

// Metodo chiamato quando il pulsante "Yes" viene premuto
public void onYesButtonClick(GButton source, GEvent event) {
  // Aggiungi qui il codice per gestire l'azione quando viene premuto il pulsante "Yes"
  manager.AnswerToContinuePlaying(true);
  disposeNewUI();
}

// Metodo chiamato quando il pulsante "No" viene premuto
public void onNoButtonClick(GButton source, GEvent event) {
  // Aggiungi qui il codice per gestire l'azione quando viene premuto il pulsante "No"
  manager.AnswerToContinuePlaying(false);
  disposeNewUI();
}

void disposeNewUI() {
  endMessage.dispose();
  questionLabel.dispose();
  yesButton.dispose();
  noButton.dispose();
  newPanel.dispose();
  newPanel = null;
}
