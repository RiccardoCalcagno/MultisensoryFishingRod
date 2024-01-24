import java.io.*;

String writeCSVRow(SessionData sessionData) {
  String playerName = sessionData.playerInfo.playerName;
  float attractingFishScore = sessionData.AttractingFishScore;
  float hookingFishScore = sessionData.HookingFishScore;
  float retreivingFishScore = sessionData.RetreivingFishScore;
  boolean sight = sessionData.playerInfo.selectedModalities[0];
  boolean audio = sessionData.playerInfo.selectedModalities[1];
  boolean haptic = sessionData.playerInfo.selectedModalities[2];
  String endReason = sessionData.endReason;
  String dateTime = sessionData.dateTime;
  float demagedWire = sessionData.demagedWire;
  float sessionTime = (float(sessionData.endTime - sessionData.startTime) / frameRate);
  
  String output="";
  String filename = "output.csv";
  boolean fileExists = new File(dataPath(filename)).exists();
  
  String[] lines = loadStrings(dataPath(filename));

  try {
    PrintWriter csvWriter = new PrintWriter(new FileWriter(dataPath(filename), true));

    // Se il file non esiste, scrive l'intestazione
    if (lines == null || lines.length == 0) {
      csvWriter.println("DateTime,PlayerName,SessionDuration,AttractingFishScore,HookingFishScore,RetreivingFishScore, DamagedWire ,sight,audio,haptic,endReason");
    }

    // Scrive i valori della riga nel file CSV
    output = dateTime + "," + playerName + "," + sessionTime + "," + attractingFishScore + "," + hookingFishScore + "," + retreivingFishScore + "," + demagedWire + "," + sight + "," + audio + "," + haptic + "," + endReason;
    csvWriter.println(output);

    csvWriter.flush();
    csvWriter.close();
    println("Riga scritta con successo in " + filename);
  } catch (IOException e) {
    println("Si è verificato un errore durante la scrittura del file CSV: " + e);
  }
  
  return output;
}


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


PVector getAccellerationInScene(RawMotionData data, boolean isRightHanded){
    //Supposto tenere la canna a 30° dall orizzontale
    float cleanX = constrain((constrain(data.acc_z, 0.588, 1) - 0.794) / 0.206, -1, 1); 
    float cleanY = constrain((constrain(data.acc_y, 0.588, 1) - 0.794) / 0.206, -1, 1);
    float cleanZ = constrain((constrain(data.acc_x, 0.62, 1) - 0.81) / 0.19, -1, 1);
    if(isRightHanded == false){
      cleanX = -cleanX;
      cleanY = -cleanY;
    }
    var rotationHelper = new Vec3(cleanX, cleanY, cleanZ);
    rotationHelper.rotateX(PI / 6);
    //rotationHelper.y += 0.82;
    return rotationHelper;
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



class VerletNode {
  PVector position;
  PVector oldPosition;
  ArrayList<PVector> lazyForcesToApply = new ArrayList<PVector>();
  PVector lazyTargetToApply = null;
  float intensityOfTarget;
  
  
  VerletNode(PVector startPos) {
    position = startPos.copy();
    oldPosition = startPos.copy();
  }
  
  void cacheForce(PVector force){
    lazyForcesToApply.add(force);
  }
  
  void cacheTarget(PVector target, float intensity){
    lazyTargetToApply = target;
    intensityOfTarget = constrain(intensity, 0, 1);
  }
  
  void applyCachedForces(){
    oldPosition = position.copy();
    for (PVector force : lazyForcesToApply) {
       position.add(force);
    }
    lazyForcesToApply.clear();
  }
  
  void applyConstrains(VerletNode next, float nodeDistance, float iterationPercentage){
    
      if(next != null){
        float dist = PVector.dist(position, next.position);
        float difference = 0;
        if (dist > 0) { 
          difference = (nodeDistance - dist) / dist;
        }
        PVector translateGeneric = PVector.sub(position, next.position).mult(0.5 * difference);
        position.add(translateGeneric);
        next.position.sub(translateGeneric); 
      }
      
      if(lazyTargetToApply != null) {
        PVector delta = new PVector();
        delta.lerp(PVector.sub(lazyTargetToApply, position), intensityOfTarget);
        position.add(delta);
        
        if(iterationPercentage > 0.99999){
          lazyTargetToApply = null;
        }
      }
  }
  
  void updatePosition(PVector newPos) {
    oldPosition.set(position);
    position.set(newPos);
  }
}
