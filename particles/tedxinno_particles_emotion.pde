// -----------------------------------------------------------
// EMOTION-DRIVEN PARTICLE SYSTEM FOR TEDxCMU
// -----------------------------------------------------------

import oscP5.*;
import netP5.*;

// -----------------------------------------------------------
// GLOBAL VARIABLES
// -----------------------------------------------------------
OscP5 oscP5;
Flock flock;
PGraphics xMask;
PGraphics questionMask;
PFont myFont;

String quizState = "IDLE";
int currentQuestion = 0;
String[] questions = {"CREATE or EXPLORE?", "CHAOS or ORDER?", "IMAGINE or ANALYZE?"};

HashMap<String, Float> tedScores = new HashMap<String, Float>();
PVector handPos = new PVector();
boolean handDetected = false;

ArrayList<PVector> handTrail = new ArrayList<PVector>();
int maxTrailLength = 30;
float gestureSpeed = 0;
PVector prevHandPos = new PVector();

int leftSideTime = 0;
int rightSideTime = 0;
float totalSpeed = 0;
int speedSamples = 0;

int lastRegenTime = 0;
int regenInterval = 3000;

float camRotation = 0;
ArrayList<TedPoint> tedPoints = new ArrayList<TedPoint>();
HashMap<String, Integer> emotionCounts = new HashMap<String, Integer>();

String currentEmotion = "neutral";
float emotionConfidence = 0.0;
HashMap<String, Float> emotionScores = new HashMap<String, Float>();
HashMap<String, color[]> emotionPalettes = new HashMap<String, color[]>();

color[] currentPalette = new color[5];
color[] targetPalette = new color[5];
float paletteTransition = 1.0;
float transitionSpeed = 0.02;

color flashColor = color(0);
float flashAmount = 0;
float flashFadeSpeed = 0.02;

boolean hoveredLeft = false;
boolean hoveredRight = false;
int hoverStartTime = 0;
int hoverDuration = 2500;  // 2.5 second hover to "click"
String hoveredSide = "none";

int lastClickTime = 0;
int clickCooldown = 2000;  // 2 seconds between clicks
PImage scottyImg;



// -----------------------------------------------------------
// SETUP
// -----------------------------------------------------------
void setup() {
  pixelDensity(1);
  size(720, 480, P2D);
  
  flock = new Flock();
  myFont = createFont("Helvetica-Bold", 100);
  
  // Create TEDxCMU mask
  xMask = createGraphics(width, height);
  xMask.beginDraw();
  xMask.background(0);
  xMask.fill(255);
  xMask.textAlign(CENTER, CENTER);
  xMask.textFont(myFont);
  xMask.text("TEDxCMU", width / 2, height / 2);
  xMask.endDraw();
  xMask.loadPixels();
  
  setupEmotionPalettes();
  
  updateTargetPalette("neutral");
  for (int i = 0; i < 5; i++) {
    currentPalette[i] = targetPalette[i];
  }
  
  initializeEmotionScores();
  
  // Create initial boids
  int numBoids = 3000;
  for (int i = 0; i < numBoids; i++) {
    PVector pos;
    do {
      pos = new PVector(random(width), random(height));
    } while (isInsideX(pos));
    flock.addBoid(new Boid(pos.x, pos.y));
  }

  initializeTedScores();
  scottyImg = loadImage("scotty.png");

  oscP5 = new OscP5(this, 12000);
  println("Listening for emotion data on port 12000...");
  println("Press SPACE to start, 1-7 for emotion colors");
}

// -----------------------------------------------------------
// MAIN DRAW LOOP
// -----------------------------------------------------------
void draw() {
  background(0);
  updatePaletteTransition();
    
  if (quizState.equals("IDLE")) {
    flock.run(); 
    drawIdleScreen();
    if (handDetected) {
      applyIdleHandForce();
      drawHandVisualization();
    }
  } else if (quizState.equals("QUESTION")) {
    if (flashAmount > 0) {
      flashAmount -= flashFadeSpeed;
      flashAmount = max(flashAmount, 0);
    }
    flock.run();
    drawQuestion();
    drawHoverZones();
    trackInteraction();
    detectHoverClick();
  } else if (quizState.equals("RESULT")) {
    drawTedResult();
  }
  
  drawEmotionInfo();
}

// -----------------------------------------------------------
// INPUT HANDLERS
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
  
  // Flash controls
  if (key == 'a' || key == 'A') { flashColor = color(237, 159, 61); flashAmount = 1; }
  if (key == 's' || key == 'S') { flashColor = color(0, 160, 193); flashAmount = 1; }
  if (key == 'd' || key == 'D') { flashColor = color(203, 17, 0); flashAmount = 1; }
  if (key == 'f' || key == 'F') { flashColor = color(254, 127, 0); flashAmount = 1; }
  if (key == 'g' || key == 'G') { flashColor = color(204, 204, 255); flashAmount = 1; }


  if (key == 'b' || key == 'B') {
    if (quizState.equals("QUESTION") && currentQuestion > 0) {
      currentQuestion--;
      createQuestionMask(currentQuestion);
      leftSideTime = 0;
      rightSideTime = 0;
      totalSpeed = 0;
      speedSamples = 0;
      hoveredSide = "none";
      hoverStartTime = 0;
    }
  }

  if (key == ' ') {
    handleSpaceBar();
  }
}

void oscEvent(OscMessage msg) {
  if (msg.checkAddrPattern("/emotion")) {
    String emotion = msg.get(0).stringValue();
    float confidence = msg.get(1).floatValue();
    setEmotionData(emotion, confidence);
  }

  if (msg.checkAddrPattern("/hand")) {
    float x = msg.get(0).floatValue();
    float y = msg.get(1).floatValue();
    
    handPos.x = map(x, 0, 640, 0, width);
    handPos.y = map(y, 0, 480, 0, height);
    handDetected = true;
  }
}