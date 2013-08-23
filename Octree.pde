class Octree extends AABB implements Shape3D {
  protected float    minNodeSize = 4;
  protected Octree   parent;
  protected Octree[] children;
  protected byte     numChildren;
  protected float    size, halfSize;
  protected Vec3D    offset;
  private   int      depth = 0;
  protected ArrayList<CartisianElement> cartElements;
    
  private Octree(Octree p, Vec3D o, float halfSize) {
    super(o.add(halfSize, halfSize, halfSize), new Vec3D(halfSize, halfSize, halfSize));
    this.parent      = p;
    this.halfSize    = halfSize;
    this.size        = halfSize * 2;
    this.offset      = o;
    this.numChildren = 0;
    if(parent!=null) {
      depth = parent.depth + 1;
      minNodeSize = parent.minNodeSize;
    }
  }
  
  public Octree(Vec3D origin, float size) {
    this(null, origin.subSelf(size/2, size/2, size/2), size / 2);
  }

  public boolean addElements(ArrayList<CartisianElement> cartisianElements) {
    boolean addedAll = true;
    for (CartisianElement ce : cartisianElements) {
       addedAll &= addElement(ce);
    }
    return addedAll;
  } 
  
  public boolean addElement(CartisianElement ce) {
    //println(ce.pos + ", " + this.offset);
    //println(containsPoint(ce.pos));
    if(containsPoint(ce.pos)) {
      if(halfSize <= minNodeSize) { // this is obviously for the first point but what does halfSize implies?
        if(cartElements == null) cartElements = new ArrayList<CartisianElement>();
        cartElements.add(ce);
        return true;
      } else {
        Vec3D plocal = ce.pos.sub(offset);
        if(children==null) children = new Octree[8];
        int octant = getOctantID(plocal);
        if(children[octant] == null) {
          Vec3D off = offset.add(new Vec3D(
                            (octant & 1) != 0 ? halfSize : 0,
                            (octant & 2) != 0 ? halfSize : 0,
                            (octant & 4) != 0 ? halfSize : 0));
          children[octant] = new Octree(this, off, halfSize * 0.5f);
          numChildren++;
        }
        return children[octant].addElement(ce);
      }
    }
    return false;
  }
  
  public boolean containsPoint(ReadonlyVec3D p) {
      return p.isInAABB(this);
  }
    
  protected final int getOctantID(Vec3D plocal) {
      return (plocal.x >= halfSize ? 1 : 0) + (plocal.y >= halfSize ? 2 : 0) + (plocal.z >= halfSize ? 4 : 0);
  }


  public Octree[] getChildren() {
    if (children != null) {
      Octree[] clones = new Octree[8];
      System.arraycopy(children, 0, clones, 0, 8);
      return clones;
    }
    return null;
  }

  public int getDepth() {
    return depth;
  }

  public float getNodeSize() {
    return size;
  }

  public int getNumChildren() {
    return numChildren;
  }
    
  public void empty() {
    numChildren = 0;
    children = null;
    cartElements = null;
  }
  
  void draw() {
    drawNode(this);
  }

  void drawNode(Octree n) {
    if (n.getNumChildren() > 0) {
      noFill();
      stroke(255-n.getDepth(), 20);
      strokeWeight(1);
      pushMatrix(); 
      translate(n.x, n.y, n.z);
      box(n.getNodeSize());
      popMatrix();
      Octree[] childNodes=n.getChildren();
      for (int i = 0; i < 8; i++) {
        if(childNodes[i] != null) drawNode(childNodes[i]); 
      }
    }
  }
}
