// -----------------------------------------------------------
// FLOCK CLASS
// -----------------------------------------------------------

class Flock {
    ArrayList<Boid> boids = new ArrayList<Boid>();
    SpatialGrid grid = new SpatialGrid();
    
    void run() {
      grid.clear();
      for (Boid b : boids) {
        grid.insert(b);
      }
      
      for (Boid b : boids) {
        b.run(boids, grid);
      }
    }
    
    void addBoid(Boid b) {
      boids.add(b);
    }
  }