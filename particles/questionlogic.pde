// -----------------------------------------------------------
// QUESTION AND INTERACTION LOGIC
// -----------------------------------------------------------

void initializeTedScores() {
    String[] tedTypes = {"Tartan Scotty", "Robo-Scotty", "Artsy Scotty", "Buggy Scotty", "All-nighter Scotty", 
                        "Plaid Scotty", "Startup Scotty", "Fence Scotty"};
    for (String type : tedTypes) {
      tedScores.put(type, 0.0);
    }
  }
  
  void createQuestionMask(int questionNum) {
    questionMask = createGraphics(width, height);
    questionMask.beginDraw();
    questionMask.background(0);
    questionMask.fill(255);
    questionMask.textAlign(CENTER, CENTER);
    questionMask.textFont(myFont);
    questionMask.textSize(50);
    
    String[] parts = questions[questionNum].split(" or ");
    questionMask.text(parts[0], width/4, height/2);
    questionMask.text(parts[1], 3*width/4, height/2);
    
    questionMask.endDraw();
    questionMask.loadPixels();
  }
  
  void handleSpaceBar() {
    if (quizState.equals("IDLE")) {
      quizState = "QUESTION";
      currentQuestion = 0;
      createQuestionMask(currentQuestion);
      leftSideTime = 0;
      rightSideTime = 0;
      totalSpeed = 0;
      speedSamples = 0;
    } else if (quizState.equals("QUESTION")) {
      currentQuestion++;
      if (currentQuestion >= questions.length) {
        quizState = "RESULT";
      } else {
        createQuestionMask(currentQuestion);
        leftSideTime = 0;
        rightSideTime = 0;
        totalSpeed = 0;
        speedSamples = 0;
      }
    } else if (quizState.equals("RESULT")) {
      quizState = "IDLE";
      for (String type : tedScores.keySet()) tedScores.put(type, 0.0);
    }
  }
  
  void trackInteraction() {
    if (handDetected) {
      handTrail.add(handPos.copy());
      if (handTrail.size() > maxTrailLength) {
        handTrail.remove(0);
      }
      
      gestureSpeed = handPos.dist(prevHandPos);
      prevHandPos = handPos.copy();
      
      applyHandForce();
      drawHandVisualization();
      
      if (frameCount % 60 == 0) {
        scoreInteraction();
      }
    }
  }
  
  void scoreInteraction() {
    boolean leftSide = handPos.x < width/2;
    
    if (leftSide) leftSideTime++;
    else rightSideTime++;
    
    totalSpeed += gestureSpeed;
    speedSamples++;
    
    float avgSpeed = (speedSamples > 0) ? totalSpeed / speedSamples : 0;
    boolean fastMovement = avgSpeed > 3;
    
    // Question-specific scoring
    switch(currentQuestion) {
      case 0:  // CREATE or EXPLORE
      if (leftSide && !fastMovement) {
        tedScores.put("Artsy Scotty", tedScores.get("Artsy Scotty") + 0.1);
        tedScores.put("Tartan Scotty", tedScores.get("Tartan Scotty") + 0.05);
      }
      if (leftSide && fastMovement) {
        tedScores.put("Startup Scotty", tedScores.get("Startup Scotty") + 0.1);
        tedScores.put("Fence Scotty", tedScores.get("Fence Scotty") + 0.05);
      }
      if (!leftSide && !fastMovement) {
        tedScores.put("Robo-Scotty", tedScores.get("Robo-Scotty") + 0.1);
        tedScores.put("All-nighter Scotty", tedScores.get("All-nighter Scotty") + 0.05);
      }
      if (!leftSide && fastMovement) {
        tedScores.put("Buggy Scotty", tedScores.get("Buggy Scotty") + 0.1);
        tedScores.put("Tartan Scotty", tedScores.get("Tartan Scotty") + 0.05);
      }
      break;
      
    case 1:  // CHAOS or ORDER
      if (leftSide) {
        tedScores.put("Fence Scotty", tedScores.get("Fence Scotty") + 0.1);
        tedScores.put("Startup Scotty", tedScores.get("Startup Scotty") + 0.05);
      }
      if (!leftSide) {
        tedScores.put("Plaid Scotty", tedScores.get("Plaid Scotty") + 0.1);
        tedScores.put("All-nighter Scotty", tedScores.get("All-nighter Scotty") + 0.05);
      }
      break;
      
    case 2:  // IMAGINE or ANALYZE
      if (leftSide) {
        tedScores.put("Tartan Scotty", tedScores.get("Tartan Scotty") + 0.1);
        tedScores.put("Artsy Scotty", tedScores.get("Artsy Scotty") + 0.05);
      }
      if (!leftSide) {
        tedScores.put("Robo-Scotty", tedScores.get("Robo-Scotty") + 0.1);
        tedScores.put("Plaid Scotty", tedScores.get("Plaid Scotty") + 0.05);
      }
      break;
    }
    
    // Emotion modifiers
    if (currentEmotion.equals("happy")) {
      tedScores.put("Tartan Scotty", tedScores.get("Tartan Scotty") + 0.02);
      tedScores.put("Buggy Scotty", tedScores.get("Buggy Scotty") + 0.02);
    }
    if (currentEmotion.equals("neutral") || currentEmotion.equals("sad")) {
      tedScores.put("Robo-Scotty", tedScores.get("Robo-Scotty") + 0.02);
    }
  
    if (!emotionCounts.containsKey(currentEmotion)) {
      emotionCounts.put(currentEmotion, 0);
    }
    emotionCounts.put(currentEmotion, emotionCounts.get(currentEmotion) + 1);
  }
  
  void applyHandForce() {
    boolean leftSide = handPos.x < width/2;
    
    for (Boid b : flock.boids) {
      if (isInsideX(b.position)) continue;
      
      float d = PVector.dist(b.position, handPos);
      if (d > 200) continue;
      
      switch(currentQuestion) {
        case 0:
          applyCreateExploreForce(b, leftSide, d);
          break;
        case 1:
          applyChaosOrderForce(b, leftSide, d);
          break;
        case 2:
          applyImagineAnalyzeForce(b, leftSide, d);
          break;
      }
    }
  }
  
  void applyCreateExploreForce(Boid b, boolean isCreate, float d) {
    if (isInsideX(b.position)) return;
    
    if (isCreate) {
      PVector toHand = PVector.sub(handPos, b.position);
      float angle = toHand.heading() + HALF_PI;
      PVector orbit = new PVector(cos(angle), sin(angle));
      orbit.mult(0.2);
      b.acceleration.add(orbit);
    } else {
      if (d < 120) {
        PVector scatter = PVector.sub(b.position, handPos);
        scatter.normalize();
        scatter.mult(0.15);
        b.acceleration.add(scatter);
      }
    }
  }
  
  void applyChaosOrderForce(Boid b, boolean isChaos, float d) {
    if (isChaos) {
      if (d < 120) {
        PVector toHand = PVector.sub(handPos, b.position);
        float angle = toHand.heading() + HALF_PI;
        PVector swirl = new PVector(cos(angle), sin(angle));
        swirl.mult(0.15);
        b.acceleration.add(swirl);
      }
    } else {
      if (d < 120) {
        float gridSize = 30;
        float targetX = round(b.position.x / gridSize) * gridSize;
        float targetY = round(b.position.y / gridSize) * gridSize;
        
        PVector target = new PVector(targetX, targetY);
        PVector toGrid = PVector.sub(target, b.position);
        toGrid.mult(0.05);
        b.acceleration.add(toGrid);
      }
    }
  }
  
  void applyImagineAnalyzeForce(Boid b, boolean isImagine, float d) {
    if (isImagine) {
      if (d < 150) {
        float angle = noise(b.position.x * 0.01, b.position.y * 0.01, frameCount * 0.01) * TWO_PI * 2;
        PVector flow = new PVector(cos(angle), sin(angle));
        flow.mult(0.25);
        
        PVector toHand = PVector.sub(handPos, b.position);
        toHand.normalize();
        toHand.mult(0.05);
        
        b.acceleration.add(flow);
        b.acceleration.add(toHand);
      }
    } else {
      if (d < 120) {
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


  void detectHoverClick() {
    if (!handDetected) return;
    
    if (millis() - lastClickTime < clickCooldown) {
      hoveredSide = "none";  // Don't allow hovering during cooldown
      return;
    }
    
    boolean isLeft = handPos.x < width/2;
    boolean isNearText = false;
    
    // Check if hand is actually near the text
    if (isLeft) {
      if (handPos.x > width/4 - 150 && handPos.x < width/4 + 150 &&
          handPos.y > height/2 - 80 && handPos.y < height/2 + 80) {
        isNearText = true;
      }
    } else {
      if (handPos.x > 3*width/4 - 150 && handPos.x < 3*width/4 + 150 &&
          handPos.y > height/2 - 80 && handPos.y < height/2 + 80) {
        isNearText = true;
      }
    }
    
    if (isNearText) {
      String currentSide = isLeft ? "left" : "right";
      
      if (!hoveredSide.equals(currentSide)) {
        hoveredSide = currentSide;
        hoverStartTime = millis();
      }
      
      int hoverTime = millis() - hoverStartTime;
      
      if (hoverTime >= hoverDuration) {
        makeChoice(isLeft);
        lastClickTime = millis();  // NEW: Record click time
      }
    } else {
      hoveredSide = "none";
    }
  }

void makeChoice(boolean choseLeft) {
  // Advance to next question
  currentQuestion++;
  if (currentQuestion >= questions.length) {
    quizState = "RESULT";
  } else {
    createQuestionMask(currentQuestion);
    leftSideTime = 0;
    rightSideTime = 0;
    totalSpeed = 0;
    speedSamples = 0;
  }
  
  // Reset hover tracking
  hoveredSide = "none";
  hoverStartTime = 0;
}