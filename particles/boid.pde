// -----------------------------------------------------------
// BOID CLASS
// -----------------------------------------------------------

class Boid {
    PVector position, velocity, acceleration, storedDirection;
    boolean inX = false;
    float r, maxforce, maxspeed, normalSpeed;
    
    Boid(float x, float y) {
      acceleration = new PVector();
      float angle = random(TWO_PI);
      velocity = new PVector(cos(angle), sin(angle));
      position = new PVector(x, y);
      storedDirection = velocity.copy().normalize();
      r = random(0.9, 1.3);
      maxspeed = random(4, 7);
      normalSpeed = maxspeed;
      maxforce = 0.1;
    }
    
    void run(ArrayList<Boid> boids, SpatialGrid grid) {
      boolean nowInside = isInsideX(position);
      if (nowInside) {
        if (!inX) storedDirection = velocity.copy().normalize();
        inX = true;
        moveInsideWithSeparation(grid);
      } else {
        inX = false;
        flock(grid);
        update();
      }
      borders();
      render();
    }
    
    void moveInsideWithSeparation(SpatialGrid grid) {
      PVector sep = separate(grid);
      sep.mult(1.4);
      acceleration.add(sep);
      velocity = storedDirection.copy();
      velocity.mult(normalSpeed * 0.15);
      velocity.add(acceleration);
      position.add(velocity);
      acceleration.mult(0);
    }
    
    void flock(SpatialGrid grid) {
      PVector sep = separate(grid);
      PVector ali = align(grid);
      PVector coh = cohesion(grid);
      sep.mult(1.5);
      ali.mult(1.0);
      coh.mult(1.0);
      acceleration.add(sep);
      acceleration.add(ali);
      acceleration.add(coh);
    }
    
    void update() {
      velocity.add(acceleration);
      velocity.limit(maxspeed);
      position.add(velocity);
      acceleration.mult(0);
    }
    
    void render() {
      float baseRadius = map(maskDepth(position), 0, 1, 1.0, 1.6);
      float time = millis() * 0.0005;
      float cx = width/2 + map(noise(time, 0), 0, 1, -50, 50);
      float cy = height/2 + map(noise(0, time), 0, 1, -50, 50);
      
      float nx = position.x * 0.01;
      float ny = position.y * 0.01;
      float noiseOffset = map(noise(nx, ny, time), 0, 1, -30, 30);
      
      float d = dist(position.x, position.y, cx + noiseOffset, cy + noiseOffset);
      float t = constrain(map(d, 0, 200, 0, 1), 0, 1);
      
      color baseCol;
      if (t < 0.25) baseCol = lerpColor(currentPalette[0], currentPalette[1], t / 0.25);
      else if (t < 0.5) baseCol = lerpColor(currentPalette[1], currentPalette[2], (t - 0.25)/0.25);
      else if (t < 0.75) baseCol = lerpColor(currentPalette[2], currentPalette[3], (t - 0.5)/0.25);
      else baseCol = lerpColor(currentPalette[3], currentPalette[4], (t - 0.75)/0.25);
      
      float brightness = map(maskDepth(position), 0, 1, 180, 255);
      color outsideCol = color(
        red(baseCol) * brightness / 255.0,
        green(baseCol) * brightness / 255.0,
        blue(baseCol) * brightness / 255.0
      );

      // float screenScale = width / 720.0;  // Compare to original width
      // baseRadius *= screenScale;

      // if (isInsideX(position)) {
      //   baseRadius *= 1.8;  // 80% bigger when inside text
      // }
          
      color finalCol = lerpColor(outsideCol, color(255), maskDepth(position));
      
      if (!isInsideX(position)) finalCol = lerpColor(finalCol, flashColor, flashAmount);
      
      fill(finalCol);
      noStroke();
      
      float theta = velocity.heading() + radians(90);
      pushMatrix();
      translate(position.x, position.y);
      rotate(theta);
      beginShape(TRIANGLES);
      vertex(0, -baseRadius * 3);
      vertex(-baseRadius, baseRadius * 3);
      vertex(baseRadius, baseRadius * 3);
      endShape(CLOSE);
      popMatrix();
    }
    
    void borders() {
      if (position.x < -r) position.x = width + r;
      if (position.y < -r) position.y = height + r;
      if (position.x > width + r) position.x = -r;
      if (position.y > height + r) position.y = -r;
    }
    
    PVector separate(SpatialGrid grid) {
      float desiredseparation = 12;
      PVector steer = new PVector();
      int count = 0;
      
      ArrayList<Boid> nearby = grid.getNearby(position, desiredseparation);
      
      for (Boid other : nearby) {
        if (other == this) continue;
        float d = PVector.dist(position, other.position);
        if (d > 0 && d < desiredseparation) {
          PVector diff = PVector.sub(position, other.position);
          diff.normalize();
          diff.div(d);
          steer.add(diff);
          count++;
        }
      }
      if (count > 0) steer.div(count);
      if (steer.mag() > 0) {
        steer.normalize();
        steer.mult(maxspeed);
        steer.sub(velocity);
        steer.limit(maxforce);
      }
      return steer;
    }
  
    PVector align(SpatialGrid grid) {
      float neighbordist = 35;
      PVector sum = new PVector();
      int count = 0;
      
      ArrayList<Boid> nearby = grid.getNearby(position, neighbordist);
      
      for (Boid other : nearby) {
        if (other == this) continue;
        float d = PVector.dist(position, other.position);
        if (d > 0 && d < neighbordist) {
          sum.add(other.velocity);
          count++;
        }
      }
      if (count > 0) {
        sum.div(count);
        sum.normalize();
        sum.mult(maxspeed);
        PVector steer = PVector.sub(sum, velocity);
        steer.limit(maxforce);
        return steer;
      }
      return new PVector();
    }
  
    PVector cohesion(SpatialGrid grid) {
      float neighbordist = 35;
      PVector sum = new PVector();
      int count = 0;
      
      ArrayList<Boid> nearby = grid.getNearby(position, neighbordist);
      
      for (Boid other : nearby) {
        if (other == this) continue;
        float d = PVector.dist(position, other.position);
        if (d > 0 && d < neighbordist) {
          sum.add(other.position);
          count++;
        }
      }
      if (count > 0) {
        sum.div(count);
        return seek(sum);
      }
      return new PVector();
    }
    
    PVector seek(PVector target) {
      PVector desired = PVector.sub(target, position);
      desired.normalize();
      desired.mult(maxspeed);
      PVector steer = PVector.sub(desired, velocity);
      steer.limit(maxforce);
      return steer;
    }
  }