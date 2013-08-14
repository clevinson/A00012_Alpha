class Flux extends Element {
  
  Vec2D pos;
  Vec2D vel;
  Vec2D acc;
  
  float mass;  
  float relaxRange;
  float affectRange, affectAmount;
  float seperationDistance, seperationForce;
  float bondingDistance, numberOfBonds;
  
  ArrayList<Flux> bonds;
  Vec2D avgBondPos;
  
  Flux(Vec2D position) {
    
    mass         = 0.9;
    relaxRange   = 0.05; // Not in pixel units ( lower = longer range );
    affectRange  = 50;  // In normal units
    affectAmount = 2;  // Degree to which Flux inherits Atoms position relatice to distance between the elements
    seperationDistance = 25;
    seperationForce    = 3;
    bondingDistance    = 20;
    numberOfBonds      = 4;
    
    type = "Flux";
    pos = position;
    vel = new Vec2D(0,0);
    acc = new Vec2D(0,0);
    avgBondPos = new Vec2D(0,0);
    bonds = new ArrayList<Flux>();
  }
  
  Flux(JSONObject flux) {  
    mass          = flux.getFloat("mass");
    relaxRange    = flux.getFloat("relaxRange");
    affectRange   = flux.getFloat("affectRange");
    affectAmount  = flux.getFloat("affectAmount");
    seperationDistance = flux.getFloat("seperationDistance");
    seperationForce    = flux.getFloat("seperationForce");
    bondingDistance    = flux.getFloat("bondingDistance");
    numberOfBonds      = flux.getFloat("numberOfBonds");
    
    type = flux.getString("type");
    pos  = new Vec2D();
    vel  = new Vec2D( flux.getJSONArray("vel").getFloat(0), flux.getJSONArray("vel").getFloat(1));
    acc  = new Vec2D();
    avgBondPos = new Vec2D();
    bonds = new ArrayList<Flux>();
    
  }
  
  void reactWith(Element element) {
      if(element.type.equals("Atom")) reactWithAtom((Atom) element);
      if(element.type.equals("Boundary")) reactWith((Boundary) element);
      if(element.type.equals("Flux")) reactWithFlux((Flux) element);
  }
  
  void reactWithAtom(Atom atom) {
    float affect = affectFunction(pos.distanceTo(atom.pos));
    if(affect > 0) {
      Vec2D dir = atom.pos.sub(pos).normalize();  // issue?
      vel.addSelf(dir.scale(affect));
    }
  }
  
  void reactWithBoundary(Boundary boundary) {
    boundary.reactWithFlux(this);
  }
  
  void reactWithFlux(Flux flux) {
    if(flux.pos.distanceTo(pos) < bondingDistance) {
      if( !bonds.contains(flux) ) {
        addBond(flux);
        flux.addBond(this);
      }
    }
  }
  
  void act() {
    updateBondRelation();
    updateMovement();
  }
  
  void depart() {
    breakAllBonds();
  }
  
  void updateBondRelation() {
    avgBondPos = new Vec2D();
    if(bonds.size() > 0) {
      for(Flux bond : bonds) {
        avgBondPos.addSelf(bond.pos);
        if( seperationFunction(pos.distanceTo(bond.pos)) > 0.01 ) {
          Vec2D dir = pos.sub(bond.pos).normalize();
          vel.addSelf(dir.scale(seperationFunction(pos.distanceTo(bond.pos))));
        }
      }
      avgBondPos.scaleSelf( 1 / (float)bonds.size() );
    }
  }
  
  void updateMovement() {
    Vec2D dir = avgBondPos.sub(pos).normalize();  
    if(avgBondPos.isZeroVector()) dir.clear();
    acc = dir.scale(relaxFunction( pos.distanceTo(avgBondPos)) );
    vel.addSelf(acc);
    vel.scaleSelf(mass);
    vel.limit(2);
    pos.addSelf(vel);
    acc.clear();
  }
  
  void addBond(Flux flux) {
    if( !bonds.contains(flux) ) {
      bonds.add(flux);
      if(bonds.size() > numberOfBonds) {
        Flux furtherst = flux;
        float maxdist = 0;
        for(Flux f : bonds) {
          float fdist = pos.distanceTo(f.pos);
          if(fdist > maxdist) {
            maxdist = fdist;
            furtherst = f;
          }
        }
        bonds.remove(furtherst);
      }
    }
  }
  
  void removeBond(Flux flux) {
    bonds.remove(flux);
  }
  
  void breakAllBonds() {
    for(Flux bond : bonds) {
      println("Before: " + bond.bonds.contains(this));
      bond.removeBond(this);
      println("After: " + bond.bonds.contains(this));
    }
    bonds.clear();
  }
  
  float relaxFunction(float x) {
    return pow( x * relaxRange, 4 ) * 10;
  }
  
  float seperationFunction(float x) {
    float e = (float) Math.E;
    return seperationForce * pow( e, -1*( (x*x) / (2*pow((seperationDistance*0.25),2))) );
  }
  
  float affectFunction(float x) {
    float e = (float) Math.E;
    return affectAmount * pow( e, -1*( (x*x) / (2*pow((affectRange*0.25),2))) );
  }
  
  JSONObject toJSON() {
    JSONObject JSONElement = new JSONObject();
    JSONElement.setString("type", type);
    JSONElement.setFloat("mass", mass);
    JSONElement.setFloat("relaxRange", relaxRange);
    JSONElement.setFloat("affectRange", affectRange);
    JSONElement.setFloat("affectAmount", affectAmount);
    JSONElement.setFloat("seperationDistance", seperationDistance);
    JSONElement.setFloat("seperationForce", seperationForce);
    JSONElement.setFloat("bondingDistance", bondingDistance);
    JSONElement.setFloat("numberOfBonds", numberOfBonds);
    JSONElement.setJSONArray("vel", new JSONArray().setFloat(0, (float)vel.x).setFloat(1, (float)vel.y));
    return JSONElement;
  }
}
