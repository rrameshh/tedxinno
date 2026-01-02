class TedPoint {
    PVector pos;
    int type;  // 0=head/body, 1=eyes/features
    
    TedPoint(float x, float y, float z, int t) {
      pos = new PVector(x, y, z);
      type = t;
    }
  }