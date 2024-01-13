

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
