// -----------------------------------------------------------
// EMOTION PALETTE MANAGEMENT
// -----------------------------------------------------------

void setupEmotionPalettes() {
    emotionPalettes.put("happy", new color[] {
      color(255, 223, 0), color(255, 179, 0), color(255, 105, 180),
      color(255, 140, 0), color(255, 215, 0)
    });
    
    emotionPalettes.put("sad", new color[] {
      color(70, 130, 180), color(100, 149, 237), color(112, 128, 144),
      color(135, 206, 250), color(176, 196, 222)
    });
    
    emotionPalettes.put("angry", new color[] {
      color(220, 20, 60), color(255, 69, 0), color(178, 34, 34),
      color(255, 0, 0), color(139, 0, 0)
    });
    
    emotionPalettes.put("surprised", new color[] {
      color(255, 255, 0), color(0, 255, 255), color(255, 0, 255),
      color(255, 215, 0), color(64, 224, 208)
    });
    
    emotionPalettes.put("fearful", new color[] {
      color(75, 0, 130), color(72, 61, 139), color(123, 104, 238),
      color(25, 25, 112), color(138, 43, 226)
    });
    
    emotionPalettes.put("disgusted", new color[] {
      color(107, 142, 35), color(85, 107, 47), color(154, 205, 50),
      color(128, 128, 0), color(189, 183, 107)
    });
    
    emotionPalettes.put("neutral", new color[] {
      color(204, 204, 255), color(254, 127, 0), color(203, 17, 0),
      color(0, 160, 193), color(237, 159, 61)
    });
  }
  
  void initializeEmotionScores() {
    emotionScores.put("happy", 0.0);
    emotionScores.put("sad", 0.0);
    emotionScores.put("angry", 0.0);
    emotionScores.put("surprised", 0.0);
    emotionScores.put("fearful", 0.0);
    emotionScores.put("disgusted", 0.0);
    emotionScores.put("neutral", 1.0);
  }
  
  void setEmotionData(String emotion, float confidence) {
    if (emotion != currentEmotion && confidence > 0.3) {
      currentEmotion = emotion;
      emotionConfidence = confidence;
      updateTargetPalette(emotion);
    }
  }
  
  void updateTargetPalette(String emotion) {
    if (emotionPalettes.containsKey(emotion)) {
      targetPalette = emotionPalettes.get(emotion);
      paletteTransition = 0.0;
    }
  }
  
  void updatePaletteTransition() {
    if (paletteTransition < 1.0) {
      paletteTransition += transitionSpeed;
      paletteTransition = min(paletteTransition, 1.0);
      
      for (int i = 0; i < 5; i++) {
        currentPalette[i] = lerpColor(currentPalette[i], targetPalette[i], paletteTransition);
      }
    }
  }