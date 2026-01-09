// -----------------------------------------------------------
// UTILITY FUNCTIONS
// -----------------------------------------------------------

boolean isInsideX(PVector p) {
    int xi = constrain(floor(p.x), 0, width-1);
    int yi = constrain(floor(p.y), 0, height-1);
    
    PGraphics currentMask = (quizState.equals("QUESTION")) ? questionMask : xMask;
    
    return red(currentMask.pixels[xi + yi * width]) > 127;
  }
  
  float maskDepth(PVector p) {
    int xi = constrain(floor(p.x), 0, width-1);
    int yi = constrain(floor(p.y), 0, height-1);
    
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