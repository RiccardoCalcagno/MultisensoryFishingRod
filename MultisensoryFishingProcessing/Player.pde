
// Dichiarazione della classe Player
class Player {
  float posX, posY, posZ; // Posizione 3D del giocatore
  GameManager gameManager; // Manager del gioco
  
  float[] wireDirection = new float[3];
  
  float damageCounter;

  // Costruttore per Player
  Player(GameManager _gameManager) {
    gameManager = _gameManager;
    posX = 0.0;
    posY = 0.0;
    posZ = 0.0;
    
    damageCounter = 100;
    
    wireDirection[0] = 1;
    wireDirection[1] = -0.5;
    wireDirection[2] = 0;
    
    // Inizializzazione delle variabili del giocatore
  }

  // Metodo per aggiornare la posizione del giocatore dai dati del loop
  void updatePosition(float x, float y, float z) {
    posX = x;
    posY = y;
    posZ = z;
    // Logica aggiuntiva se necessario in base all'aggiornamento della posizione
  }

  // Metodo per simulare l'evento di ritrazione del filo
  void damageWire(float value) {
    damageCounter -= value;
    
    if(damageCounter < 0){
      gameManager.OnWireBreaks();
    }
  }

}
