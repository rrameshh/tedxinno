// -----------------------------------------------------------
// SPATIAL GRID FOR FAST NEIGHBOR LOOKUP
// -----------------------------------------------------------

class SpatialGrid {
    int cellSize = 50;
    HashMap<Integer, ArrayList<Boid>> grid;
    ArrayList<Boid> reusableList = new ArrayList<Boid>();
    
    SpatialGrid() {
      grid = new HashMap<Integer, ArrayList<Boid>>();
    }
    
    void clear() {
      grid.clear();
    }
    
    void insert(Boid b) {
      int key = getKey(b.position);
      if (!grid.containsKey(key)) {
        grid.put(key, new ArrayList<Boid>());
      }
      grid.get(key).add(b);
    }
    
    ArrayList<Boid> getNearby(PVector pos, float radius) {
      reusableList.clear();
      int cellRadius = ceil(radius / cellSize);
      int cx = floor(pos.x / cellSize);
      int cy = floor(pos.y / cellSize);
      
      for (int dx = -cellRadius; dx <= cellRadius; dx++) {
        for (int dy = -cellRadius; dy <= cellRadius; dy++) {
          int key = getKey((cx + dx) * cellSize, (cy + dy) * cellSize);
          if (grid.containsKey(key)) {
            reusableList.addAll(grid.get(key));
          }
        }
      }
      return reusableList;
    }
    
    int getKey(PVector pos) {
      return getKey(pos.x, pos.y);
    }
    
    int getKey(float x, float y) {
      int cx = floor(x / cellSize);
      int cy = floor(y / cellSize);
      int a = (cx >= 0) ? 2 * cx : -2 * cx - 1;
      int b = (cy >= 0) ? 2 * cy : -2 * cy - 1;
      return (a >= b) ? a * a + a + b : a + b * b;
    }
  }