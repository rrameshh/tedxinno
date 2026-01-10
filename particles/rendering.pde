// -----------------------------------------------------------
// RENDERING FUNCTIONS
// -----------------------------------------------------------

void drawIdleScreen() {
    // TEDxCMU text is already filled with particles (from setup)
    // Let people play with ALL the particle behaviors at once
    
    fill(255);
    textSize(48);
    textAlign(CENTER, TOP);
    text("TEDxCMU", width/2, 30);
    
    textSize(28);
    fill(255, 200);
    text("Move your hand to explore", width/2, 70);
    text("Press SPACE when ready to discover your Scotty", width/2, height - 40);
    
    // Show what behavior is active based on hand position
    if (handDetected) {
      String currentBehavior = getIdleBehavior();
      textSize(24);
      fill(currentPalette[0]);
      text(currentBehavior, handPos.x, handPos.y - 30);
    }
  }
  void drawQuestion() {
    fill(255);
    textSize(32);
    textAlign(CENTER, TOP);
    String[] parts = questions[currentQuestion].split(" or ");
    text(parts[0] + " or " + parts[1] + "?", width/2, 20);
    
    textSize(28);
    text("Question " + (currentQuestion + 1) + " of " + questions.length, width/2, 65);
    
    textSize(24);
    int timeSinceClick = millis() - lastClickTime;
    if (timeSinceClick < clickCooldown) {
      fill(255, 100);
      text("Next question loading...", width/2, height - 30);
    } else {
      fill(255, 180);
      text("Hover over a word for 1 second to choose", width/2, height - 30);
      
      if (!hoveredSide.equals("none")) {
        int hoverTime = millis() - hoverStartTime;
        float progress = constrain(hoverTime / float(hoverDuration), 0, 1);
        fill(255);
        text("Selecting... " + int(progress * 100) + "%", width/2, height - 50);
      }
    }
  }

  void drawHandVisualization() {
    // Draw hand trail
    noFill();
    stroke(255, 100);
    strokeWeight(2);
    beginShape();
    for (PVector p : handTrail) {
      vertex(p.x, p.y);
    }
    endShape();
    
    // Determine which side and get color
    boolean leftSide = handPos.x < width/2;
    color handColor;
    if (leftSide) {
      handColor = currentPalette[0];
    } else {
      handColor = currentPalette[4];
    }
    
    // Draw hand position with colored glow
    noStroke();
    
    // Calculate hover progress ONLY when actually hovering
    float hoverProgress = 0;
    if (!hoveredSide.equals("none")) {  // ONLY calculate when hovering
      int hoverTime = millis() - hoverStartTime;
      hoverProgress = constrain(hoverTime / float(hoverDuration), 0, 1);
      
      // Outer glow (grows with hover)
      float glowSize = lerp(40, 80, hoverProgress);
      fill(red(handColor), green(handColor), blue(handColor), 50);
      ellipse(handPos.x, handPos.y, glowSize, glowSize);
      
      // Progress ring - ONLY draw when hovering
      noFill();
      stroke(handColor);
      strokeWeight(4);
      arc(handPos.x, handPos.y, 35, 35, -HALF_PI, -HALF_PI + hoverProgress * TWO_PI);
    } else {
      // Simple glow when not hovering
      fill(red(handColor), green(handColor), blue(handColor), 50);
      ellipse(handPos.x, handPos.y, 40, 40);
    }
    
    // Inner circle
    noStroke();
    fill(handColor);
    ellipse(handPos.x, handPos.y, 20, 20);
}
void drawHoverZones() {
  if (!handDetected) return;
  
  String[] parts = questions[currentQuestion].split(" or ");
  
  // Measure text width dynamically
  textFont(myFont);
  textSize(100);  // Same size as mask
  
  float leftWidth = textWidth(parts[0]);
  float rightWidth = textWidth(parts[1]);
  
  float padding = 40;  // Extra space around text
  
  // Left zone
  boolean hoveringLeft = (handPos.x < width/2 && 
                          handPos.x > width/4 - leftWidth/2 - padding && 
                          handPos.x < width/4 + leftWidth/2 + padding &&
                          handPos.y > height/2 - 80 && 
                          handPos.y < height/2 + 80);
  
  // Right zone  
  boolean hoveringRight = (handPos.x >= width/2 &&
                           handPos.x > 3*width/4 - rightWidth/2 - padding && 
                           handPos.x < 3*width/4 + rightWidth/2 + padding &&
                           handPos.y > height/2 - 80 && 
                           handPos.y < height/2 + 80);
  
  // Draw boxes
  noFill();
  strokeWeight(3);
  
  if (hoveringLeft) {
    stroke(currentPalette[0], 150);
    rectMode(CENTER);
    rect(width/4, height/2, leftWidth + padding*2, 160, 20);
  }
  
  if (hoveringRight) {
    stroke(currentPalette[4], 150);
    rectMode(CENTER);
    rect(3*width/4, height/2, rightWidth + padding*2, 160, 20);
  }
  
  rectMode(CORNER);  // Reset to default
}


  void drawTedResult() {
    background(0);
    
    // Find winning Scotty
    String winningScotty = "";
    float maxScore = 0;
    for (String type : tedScores.keySet()) {
      if (tedScores.get(type) > maxScore) {
        maxScore = tedScores.get(type);
        winningScotty = type;
      }
    }
    
    if (tedPoints.size() == 0) {
      generateTedBearPoints();
    }
    
    // Main title
    fill(255);
    textFont(myFont);
    textSize(48);
    textAlign(CENTER, TOP);
    text("You are a...", width/2, height * 0.05);
    
    textSize(64);
    fill(getDominantEmotionColor());
    text(winningScotty + "!", width/2, height * 0.12);
    
    // Spinning Scotty (centered)
    pushMatrix();
    translate(0, 0);
    draw3DTed();
    popMatrix();
    
    // Description
    fill(255);
    textSize(22);
    textAlign(CENTER, BOTTOM);
    String description = getScottyDescription(winningScotty);
    text(description, width/2, height * 0.78);
    
    // Stats - simple
    textSize(20);
    fill(255, 200);
    
    // Get movement style
    float avgSpeed = (speedSamples > 0) ? totalSpeed / speedSamples : 0;
    String movement = avgSpeed < 2 ? "Thoughtful" : (avgSpeed < 4 ? "Balanced" : "Energetic");
    
    // Get dominant emotion
    String dominant = "neutral";
    int maxCount = 0;
    for (String emotion : emotionCounts.keySet()) {
      if (emotionCounts.get(emotion) > maxCount) {
        maxCount = emotionCounts.get(emotion);
        dominant = emotion;
      }
    }
    
    text("Dominant emotion: " + dominant.toUpperCase(), width/2, height * 0.86);
    text("Movement style: " + movement, width/2, height * 0.91);
    
    // Restart prompt
    fill(255, 150);
    textSize(16);
    text("Press SPACE to try again", width/2, height * 0.98);
  }
  

  void generateTedBearPoints() {
    tedPoints.clear();
    
    scottyImg.loadPixels();
    
    int samples = 800;  // Number of particles
    
    for (int i = 0; i < samples; i++) {
      // Random position in image
      int px = int(random(scottyImg.width));
      int py = int(random(scottyImg.height));
      
      color c = scottyImg.pixels[py * scottyImg.width + px];
      
      // Only add particle if pixel is dark (part of Scotty silhouette)
      if (brightness(c) < 128) {
        // Map image coords to 3D space
        float x = map(px, 0, scottyImg.width, -100, 100);
        float y = map(py, 0, scottyImg.height, -80, 80);
        float z = random(-10, 10);  // Small depth for flat image
        
        // Check if it's red (scarf)
        boolean isScarf = (red(c) > 150 && green(c) < 100 && blue(c) < 100);
        int type = isScarf ? 2 : 0;
        
        tedPoints.add(new TedPoint(x, y, z, type));
      }
    }
  }
  
  void draw3DTed() {
    camRotation += 0.015;
    color dominantColor = getDominantEmotionColor();
    
    for (TedPoint tp : tedPoints) {
      PVector p = tp.pos;
      
      // Rotate around Y axis
      float rotatedX = p.x * cos(camRotation) - p.z * sin(camRotation);
      float rotatedZ = p.x * sin(camRotation) + p.z * cos(camRotation);
      
      float scale = 200 / (200 + rotatedZ);
      float screenX = width/2 + rotatedX * scale;
      float screenY = height/2 + p.y * scale;
      
      float size = 4 * scale;
      
      color c;
      if (tp.type == 2) {  // Red scarf
        c = color(220, 20, 60);
      } else {  // Scotty body
        c = dominantColor;
      }
      
      float brightness = map(rotatedZ, -100, 100, 0.6, 1.3);
      fill(red(c) * brightness, green(c) * brightness, blue(c) * brightness);
      noStroke();
      
      ellipse(screenX, screenY, size, size);
    }
  }

  String getScottyDescription(String scottyType) {
    if (scottyType.equals("Tartan Scotty")) {
      return "Optimistic, spirited, and proud of CMU traditions";
    } else if (scottyType.equals("Robo-Scotty")) {
      return "Analytical, tech-focused, and methodical";
    } else if (scottyType.equals("Artsy Scotty")) {
      return "Creative, expressive, and bold in your vision";
    } else if (scottyType.equals("Buggy Scotty")) {
      return "Social, collaborative, and team-oriented";
    } else if (scottyType.equals("All-nighter Scotty")) {
      return "Resilient, supportive, and always there when needed";
    } else if (scottyType.equals("Plaid Scotty")) {
      return "Structured, classic, and detail-oriented";
    } else if (scottyType.equals("Startup Scotty")) {
      return "Entrepreneurial, innovative, and fast-moving";
    } else if (scottyType.equals("Fence Scotty")) {
      return "Bold and unafraid to make your mark";
    }
    return "";
  }
  
  color getDominantEmotionColor() {
    String dominant = "neutral";
    int maxCount = 0;
    
    for (String emotion : emotionCounts.keySet()) {
      if (emotionCounts.get(emotion) > maxCount) {
        maxCount = emotionCounts.get(emotion);
        dominant = emotion;
      }
    }
    
    if (emotionPalettes.containsKey(dominant)) {
      return emotionPalettes.get(dominant)[0];
    }
    return color(210, 180, 140);
  }
  
  void drawEmotionInfo() {
    fill(255);
    textSize(14);
    textAlign(LEFT, TOP);
    text("Emotion: " + currentEmotion, 10, 10);
    text("Confidence: " + nf(emotionConfidence * 100, 0, 1) + "%", 10, 30);
    text("FPS: " + nf(frameRate, 0, 1), 10, 50);
    text("Boids: " + flock.boids.size(), 10, 70);
  }


  
  String getIdleBehavior() {
    // Divide screen into zones, each with different behavior
    float x = handPos.x;
    float y = handPos.y;
    
    if (x < width/3) {
      return "CREATE - Orbit";
    } else if (x < 2*width/3) {
      if (y < height/2) {
        return "CHAOS - Swirl";
      } else {
        return "IMAGINE - Flow";
      }
    } else {
      if (y < height/2) {
        return "ORDER - Grid";
      } else {
        return "ANALYZE - Rings";
      }
    }
  }
  
  void applyIdleHandForce() {
    // Apply different forces based on hand position
    float x = handPos.x;
    float y = handPos.y;
    
    for (Boid b : flock.boids) {
      if (isInsideX(b.position)) continue;
      float d = PVector.dist(b.position, handPos);
      if (d > 200) continue;
      
      if (x < width/3) {
        // CREATE zone - orbital
        PVector toHand = PVector.sub(handPos, b.position);
        float angle = toHand.heading() + HALF_PI;
        PVector orbit = new PVector(cos(angle), sin(angle));
        orbit.mult(0.2);
        b.acceleration.add(orbit);
      } else if (x < 2*width/3) {
        if (y < height/2) {
          // CHAOS zone - swirl
          PVector toHand = PVector.sub(handPos, b.position);
          float angle = toHand.heading() + HALF_PI;
          PVector swirl = new PVector(cos(angle), sin(angle));
          swirl.mult(0.15);
          b.acceleration.add(swirl);
        } else {
          // IMAGINE zone - flow
          float angle = noise(b.position.x * 0.01, b.position.y * 0.01, frameCount * 0.01) * TWO_PI * 2;
          PVector flow = new PVector(cos(angle), sin(angle));
          flow.mult(0.25);
          b.acceleration.add(flow);
        }
      } else {
        if (y < height/2) {
          // ORDER zone - grid
          float gridSize = 30;
          float targetX = round(b.position.x / gridSize) * gridSize;
          float targetY = round(b.position.y / gridSize) * gridSize;
          PVector target = new PVector(targetX, targetY);
          PVector toGrid = PVector.sub(target, b.position);
          toGrid.mult(0.05);
          b.acceleration.add(toGrid);
        } else {
          // ANALYZE zone - rings
          float radius = 40;
          PVector toHand = PVector.sub(handPos, b.position);
          float currentDist = toHand.mag();
          float targetDist = round(currentDist / radius) * radius;
          toHand.normalize();
          toHand.mult(targetDist - currentDist);
          toHand.mult(0.1);
          b.acceleration.add(toHand);
        }
      }
    }
  }
  