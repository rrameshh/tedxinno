from deepface import DeepFace
import cv2
from pythonosc import udp_client
import time

print("="*60)
print("TEDxCMU EMOTION DETECTOR")
print("="*60)

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
    
    frame_count += 1
    
    # Only analyze every 10th frame (faster)
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