import java.io.*;

void writeCSVRow(SessionData sessionData) {
  String playerName = sessionData.playerInfo.playerName;
  float score = sessionData.sessionPerformanceValue;
  boolean sight = sessionData.playerInfo.selectedModalities[0];
  boolean audio = sessionData.playerInfo.selectedModalities[1];
  boolean haptic = sessionData.playerInfo.selectedModalities[2];
  String endReason = sessionData.endReason;
  String dateTime = sessionData.dateTime;
  float sessionTime = (float(sessionData.endTime - sessionData.startTime) / frameRate);
  
  String filename = "output.csv";
  boolean fileExists = new File(dataPath(filename)).exists();
  
  String[] lines = loadStrings(dataPath(filename));

  try {
    PrintWriter csvWriter = new PrintWriter(new FileWriter(dataPath(filename), true));

    // Se il file non esiste, scrive l'intestazione
    if (lines == null || lines.length == 0) {
      csvWriter.println("DateTime,PlayerName,SessionDuration,Score,sight,audio,haptic,endReason");
    }

    // Scrive i valori della riga nel file CSV
    csvWriter.println(dateTime + "," + playerName + "," + sessionTime + "," + score  + "," + sight + "," + audio + "," + haptic + "," + endReason);

    csvWriter.flush();
    csvWriter.close();
    println("Riga scritta con successo in " + filename);
  } catch (IOException e) {
    println("Si è verificato un errore durante la scrittura del file CSV: " + e);
  }
}
