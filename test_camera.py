from deepface import DeepFace
import cv2
from pythonosc import udp_client
import time
import mediapipe as mp

print("="*60)
print("TEDxCMU EMOTION DETECTOR")
print("="*60)

mp_hands = mp.solutions.hands
mp_drawing = mp.solutions.drawing_utils
hands = mp_hands.Hands(min_detection_confidence=0.5, min_tracking_confidence=0.5)  # Lower for smoother

# Connect to Processing (localhost, port 12000)
osc_client = udp_client.SimpleUDPClient("127.0.0.1", 12000)
print("✓ OSC client ready")

# Start webcam
cap = cv2.VideoCapture(0)
if not cap.isOpened():
    print("❌ Could not open camera!")
    exit()

print("✓ Camera opened")
print("\nPress 'q' in the camera window to quit")
print("Make faces at the camera!\n")

# Create window before loop
cv2.namedWindow('Emotion Detection', cv2.WINDOW_NORMAL)

frame_count = 0

while True:
    ret, frame = cap.read()
    
    if not ret:
        print("❌ Failed to grab frame")
        break
    frame = cv2.flip(frame, 1) 
    frame_count += 1
    
    # HAND TRACKING EVERY FRAME (smooth)
    rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    hand_results = hands.process(rgb_frame)
    
    if hand_results.multi_hand_landmarks:
        for hand_landmarks in hand_results.multi_hand_landmarks:
            # Draw hand skeleton
            mp_drawing.draw_landmarks(
                frame, 
                hand_landmarks, 
                mp_hands.HAND_CONNECTIONS
            )
            
            # Get index finger tip (landmark 8)
            x = hand_landmarks.landmark[8].x * frame.shape[1]
            y = hand_landmarks.landmark[8].y * frame.shape[0]
            
            # Send hand position to Processing
            osc_client.send_message("/hand", [x, y])
    
    # EMOTION DETECTION every 10th frame (slower, heavy)
    if frame_count % 10 == 0:
        try:
            result = DeepFace.analyze(frame, actions=['emotion'], enforce_detection=False, silent=True)
            
            if isinstance(result, list):
                result = result[0]
            
            emotion = result['dominant_emotion']
            confidence = result['emotion'][emotion] / 100.0
            
            # Send to Processing
            osc_client.send_message("/emotion", [emotion, confidence])
            
            # Print to console
            print(f"🎭 {emotion.upper():12} | {confidence:5.1%}")
            
        except Exception as e:
            if frame_count % 50 == 0:
                print(f"⚠️  {str(e)[:50]}")
    
    # Show webcam feed
    cv2.imshow('Emotion Detection', frame)
    
    # Check for quit (shorter wait time)
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()
print("\n✓ Stopped")