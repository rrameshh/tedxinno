// -----------------------------------------------------------
// EMOTION-DRIVEN PARTICLE SYSTEM FOR TEDxCMU
// -----------------------------------------------------------
// This version uses camera input and emotion detection to drive particle colors
// Requires: Processing Video library

import oscP5.*;
import netP5.*;


// -----------------------------------------------------------
// VARIABLES
// -----------------------------------------------------------
OscP5 oscP5;

// Main flock object containing all boids
Flock flock;

// Offscreen graphics buffer to create a mask for the "TEDxCMU" text
PGraphics xMask;

// Font used to draw the text mask
PFont myFont;

String quizState = "IDLE";  // States: IDLE, QUESTION, ANALYZING, RESULT
int currentQuestion = 0;
String[] questions = {"CREATE or EXPLORE?", "CHAOS or ORDER?", "IMAGINE or ANALYZE?"};
HashMap<String, Float> tedScores = new HashMap<String, Float>();
PVector handPos = new PVector();  // Will come from MediaPipe
boolean handDetected = false;


// Quiz interaction tracking
ArrayList<PVector> handTrail = new ArrayList<PVector>();  // Track hand path
int maxTrailLength = 30;
float gestureSpeed = 0;
PVector prevHandPos = new PVector();
int questionStartTime = 0;

PGraphics questionMask;  // Dynamic mask for current question

int leftSideTime = 0;   // Frames spent on left
int rightSideTime = 0;  // Frames spent on right
float totalSpeed = 0;   // Accumulated speed
int speedSamples = 0;   // Number of speed samples

int lastRegenTime = 0;
int regenInterval = 3000;  // Regenerate every 3 seconds

float camRotation = 0;
ArrayList<TedPoint> tedPoints = new ArrayList<TedPoint>();  // Changed from PVector
HashMap<String, Integer> emotionCounts = new HashMap<String, Integer>();


// Emotion detection variables
String currentEmotion = "neutral";
float emotionConfidence = 0.0;
HashMap<String, Float> emotionScores = new HashMap<String, Float>();

// Emotion color palettes
HashMap<String, color[]> emotionPalettes = new HashMap<String, color[]>();

// Color transition variables
color[] currentPalette = new color[5];
color[] targetPalette = new color[5];
float paletteTransition = 1.0; // 0 = old palette, 1 = new palette
float transitionSpeed = 0.02;

// Flash variables (can still be triggered manually)
color flashColor = color(0);
float flashAmount = 0;
float flashFadeSpeed = 0.02;

// -----------------------------------------------------------
// SETUP
// -----------------------------------------------------------

void setup() {
  pixelDensity(1);
  size(720, 480, P2D);
  // size(720, 480);
  
  // Initialize the flock
  flock = new Flock();
  
  // Load the font for the text mask
  myFont = createFont("Helvetica-Bold", 100);
  
  // Create offscreen graphics buffer to draw the "TEDxCMU" mask
  xMask = createGraphics(width, height);
  xMask.beginDraw();
  xMask.background(0);
  xMask.fill(255);
  xMask.textAlign(CENTER, CENTER);
  xMask.textFont(myFont);
  xMask.text("TEDxCMU", width / 2, height / 2);
  xMask.endDraw();
  xMask.loadPixels();
  
  int whiteCount = 0;
  for (int i = 0; i < xMask.pixels.length; i++) {
    if (red(xMask.pixels[i]) > 127) whiteCount++;
  }
  println("White pixels in mask: " + whiteCount + " out of " + xMask.pixels.length);
  
  
  // Initialize emotion palettes
  setupEmotionPalettes();
  
  // Set initial palette to neutral
  updateTargetPalette("neutral");
  for (int i = 0; i < 5; i++) {
    currentPalette[i] = targetPalette[i];
  }
  
  // Initialize emotion scores
  emotionScores.put("happy", 0.0);
  emotionScores.put("sad", 0.0);
  emotionScores.put("angry", 0.0);
  emotionScores.put("surprised", 0.0);
  emotionScores.put("fearful", 0.0);
  emotionScores.put("disgusted", 0.0);
  emotionScores.put("neutral", 1.0);
  
  // Create initial boids and place them outside the text area
  int numBoids = 3000;
  for (int i = 0; i < numBoids; i++) {
    PVector pos;
    do {
      pos = new PVector(random(width), random(height));
    } while (isInsideX(pos));
    flock.addBoid(new Boid(pos.x, pos.y));
  }

  String[] tedTypes = {"Visionary", "Guardian", "Maverick", "Architect", "Connector", "Innovator", "Sage", "Catalyst"};
  for (String type : tedTypes) {
    tedScores.put(type, 0.0);
  }
    
  oscP5 = new OscP5(this, 12000);
  println("Listening for emotion data on port 12000...");
  
  println("Controls:");
  println("Press 'c' to toggle camera preview");
  println("Press '1-7' to manually test emotion colors");
  println("1=Happy, 2=Sad, 3=Angry, 4=Surprised, 5=Fearful, 6=Disgusted, 7=Neutral");
  
}


// -----------------------------------------------------------
// EMOTION PALETTE SETUP
// -----------------------------------------------------------

void setupEmotionPalettes() {
  // Happy: Warm, vibrant colors (yellows, oranges, pinks)
  emotionPalettes.put("happy", new color[] {
    color(255, 223, 0),    // Bright yellow
    color(255, 179, 0),    // Golden
    color(255, 105, 180),  // Hot pink
    color(255, 140, 0),    // Dark orange
    color(255, 215, 0)     // Gold
  });
  
  // Sad: Cool, muted blues and grays
  emotionPalettes.put("sad", new color[] {
    color(70, 130, 180),   // Steel blue
    color(100, 149, 237),  // Cornflower blue
    color(112, 128, 144),  // Slate gray
    color(135, 206, 250),  // Light sky blue
    color(176, 196, 222)   // Light steel blue
  });
  
  // Angry: Intense reds and oranges
  emotionPalettes.put("angry", new color[] {
    color(220, 20, 60),    // Crimson
    color(255, 69, 0),     // Red-orange
    color(178, 34, 34),    // Firebrick
    color(255, 0, 0),      // Pure red
    color(139, 0, 0)       // Dark red
  });
  
  // Surprised: Bright, electric colors
  emotionPalettes.put("surprised", new color[] {
    color(255, 255, 0),    // Yellow
    color(0, 255, 255),    // Cyan
    color(255, 0, 255),    // Magenta
    color(255, 215, 0),    // Gold
    color(64, 224, 208)    // Turquoise
  });
  
  // Fearful: Dark purples and deep blues
  emotionPalettes.put("fearful", new color[] {
    color(75, 0, 130),     // Indigo
    color(72, 61, 139),    // Dark slate blue
    color(123, 104, 238),  // Medium slate blue
    color(25, 25, 112),    // Midnight blue
    color(138, 43, 226)    // Blue violet
  });
  
  // Disgusted: Greens and muddy colors
  emotionPalettes.put("disgusted", new color[] {
    color(107, 142, 35),   // Olive drab
    color(85, 107, 47),    // Dark olive green
    color(154, 205, 50),   // Yellow green
    color(128, 128, 0),    // Olive
    color(189, 183, 107)   // Dark khaki
  });
  
  // Neutral: Original TEDx colors
  emotionPalettes.put("neutral", new color[] {
    color(204, 204, 255),  // Lavender
    color(254, 127, 0),    // Orange
    color(203, 17, 0),     // Red
    color(0, 160, 193),    // Blue
    color(237, 159, 61)    // Yellow
  });
}

// -----------------------------------------------------------
// DRAW LOOP
// -----------------------------------------------------------

void createQuestionMask(int questionNum) {
  questionMask = createGraphics(width, height);
  questionMask.beginDraw();
  questionMask.background(0);
  questionMask.fill(255);
  questionMask.textAlign(CENTER, CENTER);
  questionMask.textFont(myFont);
  questionMask.textSize(50);  // Slightly smaller than TEDxCMU
  
  String[] parts = questions[questionNum].split(" or ");
  
  // Left word
  questionMask.text(parts[0], width/4, height/2);
  
  // Right word  
  questionMask.text(parts[1], 3*width/4, height/2);
  
  questionMask.endDraw();
  questionMask.loadPixels();

  
}

void drawIdleScreen() {
  fill(255);
  textSize(32);
  textAlign(CENTER, CENTER);
  text("Press SPACE to discover your Ted", width/2, height/2);
}

void regenerateTextParticles() {
  // Only regenerate occasionally
  if (millis() - lastRegenTime < regenInterval) return;
  lastRegenTime = millis();
  
  // Count how many particles are inside the text
  int particlesInText = 0;
  for (Boid b : flock.boids) {
    if (isInsideX(b.position)) particlesInText++;
  }
  
  // If too few particles in text, spawn new ones
  int targetInText = 800;  // Want at least this many in text
  if (particlesInText < targetInText) {
    int toSpawn = targetInText - particlesInText;
    
    for (int i = 0; i < toSpawn && flock.boids.size() < 3000; i++) {
      // Spawn particle inside text
      PVector pos;
      int attempts = 0;
      do {
        pos = new PVector(random(width), random(height));
        attempts++;
      } while (!isInsideX(pos) && attempts < 50);
      
      if (isInsideX(pos)) {
        flock.addBoid(new Boid(pos.x, pos.y));
      }
    }
  }
}

void drawQuestion() {
  // Question text at top
  fill(255);
  textSize(16);
  textAlign(CENTER, TOP);
  String[] parts = questions[currentQuestion].split(" or ");
  text(parts[0] + " or " + parts[1] + "?", width/2, 20);
  
  // Progress indicator below
  textSize(16);
  text("Question " + (currentQuestion + 1) + " of " + questions.length, width/2, 65);
}

void scoreInteraction() {
  boolean leftSide = handPos.x < width/2;
  
  // Track time spent on each side
  if (leftSide) {
    leftSideTime++;
  } else {
    rightSideTime++;
  }
  
  // Track average movement speed
  totalSpeed += gestureSpeed;
  speedSamples++;
  
  float avgSpeed = (speedSamples > 0) ? totalSpeed / speedSamples : 0;
  boolean fastMovement = avgSpeed > 3;
  
  // Score based on current question
  switch(currentQuestion) {
    case 0:  // CREATE or EXPLORE
      if (leftSide && !fastMovement) {
        tedScores.put("Architect", tedScores.get("Architect") + 0.1);
        tedScores.put("Visionary", tedScores.get("Visionary") + 0.05);
      }
      if (leftSide && fastMovement) {
        tedScores.put("Innovator", tedScores.get("Innovator") + 0.1);
        tedScores.put("Visionary", tedScores.get("Visionary") + 0.05);
      }
      if (!leftSide && !fastMovement) {
        tedScores.put("Sage", tedScores.get("Sage") + 0.05);
        tedScores.put("Connector", tedScores.get("Connector") + 0.1);
      }
      if (!leftSide && fastMovement) {
        tedScores.put("Maverick", tedScores.get("Maverick") + 0.1);
        tedScores.put("Connector", tedScores.get("Connector") + 0.05);
      }
      break;
      

      
    case 1:  // CHAOS or ORDER
      if (leftSide) {
        tedScores.put("Maverick", tedScores.get("Maverick") + 0.1);
        tedScores.put("Catalyst", tedScores.get("Catalyst") + 0.05);
      }
      if (!leftSide) {
        tedScores.put("Architect", tedScores.get("Architect") + 0.1);
        tedScores.put("Sage", tedScores.get("Sage") + 0.05);
      }
      break;
      

      
    case 2:  // IMAGINE or ANALYZE
      if (leftSide) {
        tedScores.put("Visionary", tedScores.get("Visionary") + 0.1);
        tedScores.put("Connector", tedScores.get("Connector") + 0.05);
      }
      if (!leftSide) {
        tedScores.put("Architect", tedScores.get("Architect") + 0.1);
        tedScores.put("Sage", tedScores.get("Sage") + 0.05);
        tedScores.put("Innovator", tedScores.get("Innovator") + 0.05);
      }
      break;
  }
  
  // Emotion modifiers (optional - adds personality)
  if (currentEmotion.equals("happy")) {
    tedScores.put("Visionary", tedScores.get("Visionary") + 0.02);
    tedScores.put("Connector", tedScores.get("Connector") + 0.02);
  }
  if (currentEmotion.equals("neutral") || currentEmotion.equals("sad")) {
    tedScores.put("Sage", tedScores.get("Sage") + 0.02);
  }

  if (!emotionCounts.containsKey(currentEmotion)) {
    emotionCounts.put(currentEmotion, 0);
  }
  emotionCounts.put(currentEmotion, emotionCounts.get(currentEmotion) + 1);
}

void trackInteraction() {
  if (handDetected) {
    // Update hand trail
    handTrail.add(handPos.copy());
    if (handTrail.size() > maxTrailLength) {
      handTrail.remove(0);
    }
    
    // Calculate gesture speed
    gestureSpeed = handPos.dist(prevHandPos);
    prevHandPos = handPos.copy();
    
    // Apply particle force based on current question
    applyHandForce();
    
    // Draw hand visualization
    drawHandVisualization();
    
    // Score interaction periodically
    if (frameCount % 60 == 0) {
      scoreInteraction();
    }
  }
}

void applyHandForce() {
  boolean leftSide = handPos.x < width/2;
  
  // ONLY affect particles that are already inside text
  for (Boid b : flock.boids) {
    if (isInsideX(b.position)) continue; 
    
    float d = PVector.dist(b.position, handPos);
    if (d > 200) continue;  // Only affect nearby particles
    
    switch(currentQuestion) {
      case 0:  // CREATE or EXPLORE
        applyCreateExploreForce(b, leftSide, d);
        break;

      case 1:  // CHAOS or ORDER
        applyChaosOrderForce(b, leftSide, d);
        break;

      case 2:  // IMAGINE or ANALYZE
        applyImagineAnalyzeForce(b, leftSide, d);
        break;
    }

    
  }
}

void applyCreateExploreForce(Boid b, boolean isCreate, float d) {
  // Skip particles inside text
  if (isInsideX(b.position)) return;
  
  if (isCreate) {
    // CREATE: Particles orbit around hand
    PVector toHand = PVector.sub(handPos, b.position);
    float angle = toHand.heading() + HALF_PI;
    PVector orbit = new PVector(cos(angle), sin(angle));
    orbit.mult(0.2);
    b.acceleration.add(orbit);
  } else {
    // EXPLORE: Particles scatter outward from hand
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
    // CHAOS: Swirl
    if (d < 120) {
      PVector toHand = PVector.sub(handPos, b.position);
      float angle = toHand.heading() + HALF_PI;
      PVector swirl = new PVector(cos(angle), sin(angle));
      swirl.mult(0.15);
      b.acceleration.add(swirl);
    }
  } else {
    // ORDER: Grid snap
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
    // IMAGINE: Flowing streams using Perlin noise
    if (d < 150) {
      float angle = noise(b.position.x * 0.01, b.position.y * 0.01, frameCount * 0.01) * TWO_PI * 2;
      PVector flow = new PVector(cos(angle), sin(angle));
      flow.mult(0.25);
      
      // Bias toward hand direction
      PVector toHand = PVector.sub(handPos, b.position);
      toHand.normalize();
      toHand.mult(0.05);
      
      b.acceleration.add(flow);
      b.acceleration.add(toHand);
    }
  } else {
    // ANALYZE: Concentric circles (unchanged)
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
  
  // Draw hand position
  fill(255, 0, 0);
  noStroke();
  ellipse(handPos.x, handPos.y, 20, 20);
}

void drawTedResult() {
  background(0);
  
  // Find highest scoring Ted
  String winningTed = "";
  float maxScore = 0;
  for (String type : tedScores.keySet()) {
    if (tedScores.get(type) > maxScore) {
      maxScore = tedScores.get(type);
      winningTed = type;
    }
  }
  
  // Generate Ted points if not done yet
  if (tedPoints.size() == 0) {
    generateTedBearPoints();
  }
  
  // Title text
  fill(255);
  textSize(32);
  textAlign(CENTER, TOP);
  text("You are...", width/2, 20);
  textSize(40);
  text("The " + winningTed + " Ted", width/2, 60);
  
  // Draw 3D Ted (fake 3D using 2D projection)
  draw3DTed();
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
  return color(210, 180, 140);  // Default tan bear color
}

void draw3DTed() {
  camRotation += 0.015;
  
  color dominantColor = getDominantEmotionColor();
  
  for (TedPoint tp : tedPoints) {
    PVector p = tp.pos;
    
    float rotatedX = p.x * cos(camRotation) - p.z * sin(camRotation);
    float rotatedZ = p.x * sin(camRotation) + p.z * cos(camRotation);
    
    float scale = 250 / (250 + rotatedZ);
    float screenX = width/2 + rotatedX * scale;
    float screenY = height/2 - 30 + p.y * scale;
    
    float size = 4 * scale;
    
    color c;
    if (tp.type == 1) {  // Eyes and facial features
      c = color(50, 40, 35);  // Dark brown
    } else {  // Head/ears
      c = dominantColor;
    }
    
    float brightness = map(rotatedZ, -120, 120, 0.6, 1.3);
    fill(red(c) * brightness, green(c) * brightness, blue(c) * brightness);
    noStroke();
    
    ellipse(screenX, screenY, size, size);
  }
}

void draw() {
  background(0);
  
  // Update color palette based on detected emotion
  updatePaletteTransition();
    
  if (quizState.equals("IDLE")) {
    drawIdleScreen();
  } else if (quizState.equals("QUESTION")) {
    updatePaletteTransition();
    if (flashAmount > 0) {
      flashAmount -= flashFadeSpeed;
      flashAmount = max(flashAmount, 0);
    }
    flock.run();
    drawQuestion();
    trackInteraction();

  } else if (quizState.equals("RESULT")) {
    drawTedResult();
  }

  
  // Display current emotion info
  drawEmotionInfo();
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


void generateTedBearPoints() {
  tedPoints.clear();
  
  // Main head (big sphere)
  for (int i = 0; i < 300; i++) {
    float theta = random(TWO_PI);
    float phi = random(PI);
    float r = 80;
    float x = r * sin(phi) * cos(theta);
    float y = r * sin(phi) * sin(theta);
    float z = r * cos(phi);
    tedPoints.add(new TedPoint(x, y, z, 0));  // type 0 = head
  }
  
  // Left ear
  for (int i = 0; i < 80; i++) {
    float theta = random(TWO_PI);
    float phi = random(PI);
    float r = 30;
    float x = -60 + r * sin(phi) * cos(theta);
    float y = -70 + r * sin(phi) * sin(theta);
    float z = r * cos(phi);
    tedPoints.add(new TedPoint(x, y, z, 0));
  }
  
  // Right ear
  for (int i = 0; i < 80; i++) {
    float theta = random(TWO_PI);
    float phi = random(PI);
    float r = 30;
    float x = 60 + r * sin(phi) * cos(theta);
    float y = -70 + r * sin(phi) * sin(theta);
    float z = r * cos(phi);
    tedPoints.add(new TedPoint(x, y, z, 0));
  }
  
  // Left eye
  for (int i = 0; i < 25; i++) {
    float theta = random(TWO_PI);
    float phi = random(HALF_PI);
    float r = 8;
    float x = -25 + r * sin(phi) * cos(theta);
    float y = -15 + r * sin(phi) * sin(theta);
    float z = 70 + r * cos(phi);
    tedPoints.add(new TedPoint(x, y, z, 1));  // type 1 = features
  }
  
  // Right eye
  for (int i = 0; i < 25; i++) {
    float theta = random(TWO_PI);
    float phi = random(HALF_PI);
    float r = 8;
    float x = 25 + r * sin(phi) * cos(theta);
    float y = -15 + r * sin(phi) * sin(theta);
    float z = 70 + r * cos(phi);
    tedPoints.add(new TedPoint(x, y, z, 1));
  }
  
  // Nose
  for (int i = 0; i < 20; i++) {
    float theta = random(TWO_PI);
    float phi = random(HALF_PI);
    float r = 10;
    float x = r * sin(phi) * cos(theta);
    float y = 15 + r * sin(phi) * sin(theta);
    float z = 75 + r * cos(phi);
    tedPoints.add(new TedPoint(x, y, z, 1));
  }
  
  // Smile
  for (int i = 0; i < 15; i++) {
    float angle = map(i, 0, 14, -QUARTER_PI, QUARTER_PI);
    float x = 20 * sin(angle);
    float y = 30 + 5 * cos(angle);
    float z = 72;
    tedPoints.add(new TedPoint(x, y, z, 1));
  }
}

// -----------------------------------------------------------
// EMOTION DETECTION
// -----------------------------------------------------------

// Call this function when you receive emotion data from your API
void setEmotionData(String emotion, float confidence) {
  if (emotion != currentEmotion && confidence > 0.3) { // Threshold to avoid flickering
    currentEmotion = emotion;
    emotionConfidence = confidence;
    updateTargetPalette(emotion);
  }
}

// -----------------------------------------------------------
// PALETTE MANAGEMENT
// -----------------------------------------------------------

void updateTargetPalette(String emotion) {
  if (emotionPalettes.containsKey(emotion)) {
    targetPalette = emotionPalettes.get(emotion);
    paletteTransition = 0.0; // Start transition
  }
}

void updatePaletteTransition() {
  if (paletteTransition < 1.0) {
    paletteTransition += transitionSpeed;
    paletteTransition = min(paletteTransition, 1.0);
    
    // Smoothly interpolate between current and target palette
    for (int i = 0; i < 5; i++) {
      currentPalette[i] = lerpColor(currentPalette[i], targetPalette[i], paletteTransition);
    }
  }
}

// -----------------------------------------------------------
// KEY INTERACTION
// -----------------------------------------------------------

void keyPressed() {
  // Manual emotion testing
  if (key == '1') setEmotionData("happy", 1.0);
  if (key == '2') setEmotionData("sad", 1.0);
  if (key == '3') setEmotionData("angry", 1.0);
  if (key == '4') setEmotionData("surprised", 1.0);
  if (key == '5') setEmotionData("fearful", 1.0);
  if (key == '6') setEmotionData("disgusted", 1.0);
  if (key == '7') setEmotionData("neutral", 1.0);
  
  // Legacy flash controls
  if (key == 'a' || key == 'A') { flashColor = color(237, 159, 61); flashAmount = 1; }
  if (key == 's' || key == 'S') { flashColor = color(0, 160, 193); flashAmount = 1; }
  if (key == 'd' || key == 'D') { flashColor = color(203, 17, 0); flashAmount = 1; }
  if (key == 'f' || key == 'F') { flashColor = color(254, 127, 0); flashAmount = 1; }
  if (key == 'g' || key == 'G') { flashColor = color(204, 204, 255); flashAmount = 1; }

  if (key == ' ') {
    if (quizState.equals("IDLE")) {
      quizState = "QUESTION";
      currentQuestion = 0;
      questionStartTime = millis();
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
}

// -----------------------------------------------------------
// MASK CHECK FUNCTIONS
// -----------------------------------------------------------

boolean isInsideX(PVector p) {
  int xi = constrain(floor(p.x), 0, width-1);
  int yi = constrain(floor(p.y), 0, height-1);
  
  // Use question mask during questions, TEDxCMU mask otherwise
  PGraphics currentMask = (quizState.equals("QUESTION")) ? questionMask : xMask;
  
  return red(currentMask.pixels[xi + yi * width]) > 127;
}

float maskDepth(PVector p) {
  int xi = constrain(floor(p.x), 0, width-1);
  int yi = constrain(floor(p.y), 0, height-1);
  
  // Use question mask during questions
  PGraphics currentMask = (quizState.equals("QUESTION")) ? questionMask : xMask;
  
  float sum = 0;
  int count = 0;
  int r = 4;
  for (int dx = -r; dx <= r; dx++) {
    for (int dy = -r; dy <= r; dy++) {
      int xi2 = constrain(xi + dx, 0, width - 1);
      int yi2 = constrain(yi + dy, 0, height - 1);
      sum += red(currentMask.pixels[xi2 + yi2 * width]);
      count++;
    }
  }
  return (sum / (count * 255.0));
}

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
    reusableList.clear(); // Reuse instead of creating new
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
    // Cantor pairing function
    int a = (cx >= 0) ? 2 * cx : -2 * cx - 1;
    int b = (cy >= 0) ? 2 * cy : -2 * cy - 1;
    return (a >= b) ? a * a + a + b : a + b * b;
  }
}

// -----------------------------------------------------------
// BOID CLASS (Modified for emotion-based colors)
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
      moveInsideWithSeparation(grid);  // Pass grid
    } else {
      inX = false;
      flock(grid);  // Pass grid
      update();
    }
    borders();
    render();
  }
  
  void moveInsideWithSeparation(SpatialGrid grid) {  // Add grid parameter
    PVector sep = separate(grid);  // Pass grid
    sep.mult(1.4);
    acceleration.add(sep);
    velocity = storedDirection.copy();
    velocity.mult(normalSpeed * 0.15);
    velocity.add(acceleration);
    position.add(velocity);
    acceleration.mult(0);
  }
  
  void flock(SpatialGrid grid) {  // Add grid parameter
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
    
    // Dynamic center using Perlin noise
    float time = millis() * 0.0005;
    float cx = width/2 + map(noise(time, 0), 0, 1, -50, 50);
    float cy = height/2 + map(noise(0, time), 0, 1, -50, 50);
    
    float nx = position.x * 0.01;
    float ny = position.y * 0.01;
    float noiseOffset = map(noise(nx, ny, time), 0, 1, -30, 30);
    
    float d = dist(position.x, position.y, cx + noiseOffset, cy + noiseOffset);
    float t = constrain(map(d, 0, 200, 0, 1), 0, 1);
    
    // Use emotion-based palette instead of fixed colors
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
  
  PVector separate(SpatialGrid grid) {  // Add grid parameter
    float desiredseparation = 12;
    PVector steer = new PVector();
    int count = 0;
    
    // ONLY CHECK NEARBY BOIDS (this is the speedup!)
    ArrayList<Boid> nearby = grid.getNearby(position, desiredseparation);
    
    for (Boid other : nearby) {
      if (other == this) continue;  // Skip self
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

  PVector align(SpatialGrid grid) {  // Add grid parameter
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

  PVector cohesion(SpatialGrid grid) {  // Add grid parameter
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

// -----------------------------------------------------------
// FLOCK CLASS (with spatial grid)
// -----------------------------------------------------------

class Flock {
  ArrayList<Boid> boids = new ArrayList<Boid>();
  SpatialGrid grid = new SpatialGrid();
  
  void run() {
    // Rebuild grid each frame
    grid.clear();
    for (Boid b : boids) {
      grid.insert(b);
    }
    
    // Run each boid with grid access
    for (Boid b : boids) {
      b.run(boids, grid);
    }
  }
  
  void addBoid(Boid b) {
    boids.add(b);
  }
}
void oscEvent(OscMessage msg) {
  // When we receive emotion data from Python
  if (msg.checkAddrPattern("/emotion")) {
    String emotion = msg.get(0).stringValue();
    float confidence = msg.get(1).floatValue();
    
    // Update the particles!
    setEmotionData(emotion, confidence);
  }

  if (msg.checkAddrPattern("/hand")) {
    float x = msg.get(0).floatValue();
    float y = msg.get(1).floatValue();
    
    // Map camera coordinates to screen coordinates
    // Camera is mirrored, so flip x
    handPos.x = map(x, 0, 640, 0, width);  // Changed from (width, 0) to (0, width)
    handPos.y = map(y, 0, 480, 0, height);
    handDetected = true;
    
    println("Hand at: " + handPos.x + ", " + handPos.y);  // Debug
  }
}
