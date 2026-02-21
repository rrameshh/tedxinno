// -----------------------------------------------------------
// EMOTION PALETTE MANAGEMENT
// -----------------------------------------------------------

void setupEmotionPalettes() {
    emotionPalettes.put("happy", new color[] {
      color(244, 97, 39), color(248, 174, 1), color(251, 230, 195),
      color(228, 58, 98), color(16, 125, 228)
    });
    
    emotionPalettes.put("sad", new color[] {
      color(9, 33, 45), color(29, 108, 47), color(21, 153, 166),
      color(217, 226, 231), color(207, 78, 46)
    });
    
    emotionPalettes.put("angry", new color[] {
      color(124, 4, 324), color(171, 4, 42), color(247,55, 26), 
      color(255, 284, 32), color(212, 13, 26)

    });
    
    emotionPalettes.put("surprised", new color[] {
      color(206, 16, 20), color(244, 71, 83), color(240, 240, 240),
      color(149, 215, 237), color(26, 174, 194)
    });
    
    emotionPalettes.put("fearful", new color[] {
      color(52, 22, 57), color(36, 72, 123), color(243, 229, 255), 
      color(165, 47, 89), color(95, 66, 115)
    });
    
    emotionPalettes.put("disgusted", new color[] {
      color(10, 51, 35), color(131, 153, 88), color(255, 251, 226), 
      color(211, 150, 140), color(24, 52, 59)
    });
    
    emotionPalettes.put("neutral", new color[] {
      // color(204, 204, 255), color(254, 127, 0), color(203, 17, 0),
      // color(0, 160, 193), 
      // color(147, 112, 219)  // purple

      color(190, 5, 0), color(241, 125, 0), color(206, 204, 255),
      color(66, 161, 193), color(80, 144, 128)

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