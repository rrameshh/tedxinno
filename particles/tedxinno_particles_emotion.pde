// -----------------------------------------------------------
// EMOTION-DRIVEN PARTICLE SYSTEM FOR TEDxCMU
// -----------------------------------------------------------
// This version uses camera input and emotion detection to drive particle colors
// Requires: Processing Video library

import processing.video.*;
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

// Camera capture
Capture cam;
boolean cameraAvailable = false;

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
  size(720, 480);
  
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
  
  // Initialize camera
  setupCamera();
  
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
  int numBoids = 1500;
  for (int i = 0; i < numBoids; i++) {
    PVector pos;
    do {
      pos = new PVector(random(width), random(height));
    } while (isInsideX(pos));
    flock.addBoid(new Boid(pos.x, pos.y));
  }
  
  oscP5 = new OscP5(this, 12000);
  println("Listening for emotion data on port 12000...");
  
  println("Controls:");
  println("Press 'c' to toggle camera preview");
  println("Press '1-7' to manually test emotion colors");
  println("1=Happy, 2=Sad, 3=Angry, 4=Surprised, 5=Fearful, 6=Disgusted, 7=Neutral");
  
}

// -----------------------------------------------------------
// CAMERA SETUP
// -----------------------------------------------------------

void setupCamera() {
  String[] cameras = Capture.list();
  
  if (cameras.length == 0) {
    println("No cameras available!");
    cameraAvailable = false;
  } else {
    println("Available cameras:");
    for (int i = 0; i < cameras.length; i++) {
      println(i + ": " + cameras[i]);
    }
    
    // Use first available camera
    cam = new Capture(this, 640, 480, cameras[0]);
    cam.start();
    cameraAvailable = true;
    println("Camera initialized!");
  }
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

void draw() {
  background(0);
  
  // Update camera if available
  if (cameraAvailable && cam.available()) {
    cam.read();
    // Here you would call your emotion detection
    // For now, we'll use simulated emotion detection
    detectEmotionFromCamera();
  }
  
  // Update color palette based on detected emotion
  updatePaletteTransition();
  
  // Gradually fade the flash effect
  if (flashAmount > 0) {
    flashAmount -= flashFadeSpeed;
    flashAmount = max(flashAmount, 0);
  }
  
  // Run the flock behavior
  flock.run();
  
  // Optional: Draw camera preview (toggle with 'c' key)
  if (showCameraPreview && cameraAvailable) {
    drawCameraPreview();
  }
  
  // Display current emotion info
  drawEmotionInfo();
}

boolean showCameraPreview = false;

void drawCameraPreview() {
  pushMatrix();
  scale(0.2);
  image(cam, width * 5 - cam.width, 0);
  popMatrix();
}

void drawEmotionInfo() {
  fill(255);
  textSize(14);
  textAlign(LEFT, TOP);
  text("Emotion: " + currentEmotion, 10, 10);
  text("Confidence: " + nf(emotionConfidence * 100, 0, 1) + "%", 10, 30);
}

// -----------------------------------------------------------
// EMOTION DETECTION
// -----------------------------------------------------------

// This is a placeholder for actual emotion detection
// You would replace this with calls to your emotion detection API
void detectEmotionFromCamera() {
  // PLACEHOLDER: Simulate emotion detection
  // In a real implementation, you would:
  // 1. Send camera frame to emotion detection API
  // 2. Parse the response to get emotion probabilities
  // 3. Update emotionScores HashMap
  // 4. Determine predominant emotion
  
  // For demonstration, randomly vary emotions slowly
  if (frameCount % 180 == 0) { // Every ~3 seconds
    String[] emotions = {"happy", "sad", "angry", "surprised", "fearful", "disgusted", "neutral"};
    String newEmotion = emotions[int(random(emotions.length))];
    updateTargetPalette(newEmotion);
  }
}

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
  
  // Toggle camera preview
  if (key == 'c' || key == 'C') {
    showCameraPreview = !showCameraPreview;
  }
  
  // Legacy flash controls
  if (key == 'a' || key == 'A') { flashColor = color(237, 159, 61); flashAmount = 1; }
  if (key == 's' || key == 'S') { flashColor = color(0, 160, 193); flashAmount = 1; }
  if (key == 'd' || key == 'D') { flashColor = color(203, 17, 0); flashAmount = 1; }
  if (key == 'f' || key == 'F') { flashColor = color(254, 127, 0); flashAmount = 1; }
  if (key == 'g' || key == 'G') { flashColor = color(204, 204, 255); flashAmount = 1; }
}

// -----------------------------------------------------------
// MASK CHECK FUNCTIONS
// -----------------------------------------------------------

boolean isInsideX(PVector p) {
  int xi = constrain(floor(p.x), 0, width-1);
  int yi = constrain(floor(p.y), 0, height-1);
  return red(xMask.pixels[xi + yi * width]) > 127;
}

float maskDepth(PVector p) {
  float sum = 0;
  int count = 0;
  int r = 4;
  for (int dx = -r; dx <= r; dx++) {
    for (int dy = -r; dy <= r; dy++) {
      int xi = constrain(floor(p.x + dx), 0, width - 1);
      int yi = constrain(floor(p.y + dy), 0, height - 1);
      sum += red(xMask.pixels[xi + yi * width]);
      count++;
    }
  }
  return (sum / (count * 255.0));
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
  
  void run(ArrayList<Boid> boids) {
    boolean nowInside = isInsideX(position);
    if (nowInside) {
      if (!inX) storedDirection = velocity.copy().normalize();
      inX = true;
      moveInsideWithSeparation(boids);
    } else {
      inX = false;
      flock(boids);
      update();
    }
    borders();
    render();
  }
  
  void moveInsideWithSeparation(ArrayList<Boid> boids) {
    PVector sep = separate(boids);
    sep.mult(1.4);
    acceleration.add(sep);
    velocity = storedDirection.copy();
    velocity.mult(normalSpeed * 0.08);
    velocity.add(acceleration);
    position.add(velocity);
    acceleration.mult(0);
  }
  
  void flock(ArrayList<Boid> boids) {
    PVector sep = separate(boids);
    PVector ali = align(boids);
    PVector coh = cohesion(boids);
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
  
  PVector separate(ArrayList<Boid> boids) { 
    float desiredseparation = 12;
    PVector steer = new PVector();
    int count = 0;
    for (Boid other : boids) {
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
  
  PVector align(ArrayList<Boid> boids) {
    float neighbordist = 50;
    PVector sum = new PVector();
    int count = 0;
    for (Boid other : boids) {
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
  
  PVector cohesion(ArrayList<Boid> boids) {
    float neighbordist = 50;
    PVector sum = new PVector();
    int count = 0;
    for (Boid other : boids) {
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
// FLOCK CLASS
// -----------------------------------------------------------

class Flock {
  ArrayList<Boid> boids = new ArrayList<Boid>();
  
  void run() {
    for (Boid b : boids) b.run(boids);
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
}
