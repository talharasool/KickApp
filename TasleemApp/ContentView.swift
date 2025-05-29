import SwiftUI

struct ContentView: View {
    @StateObject private var visionProcessor = VisionProcessor()
    @State private var pickCount = 0
    @State private var kickCount = 0
    @State private var pickablePosition = CGPoint(x: 200, y: 300)
    @State private var bombPosition = CGPoint(x: 100, y: 500)
    @State private var showFeedback = false
    @State private var feedbackMessage = ""
    
    // Game area boundaries
    private let minX: CGFloat = 60
    private let maxX: CGFloat = UIScreen.main.bounds.width - 60
    private let minY: CGFloat = 100
    private let maxY: CGFloat = UIScreen.main.bounds.height - 100
    private let interactionRadius: CGFloat = 60
    
    var body: some View {
        ZStack {
            // Camera View
            CameraView { sampleBuffer in
                visionProcessor.processFrame(sampleBuffer)
            }
            .ignoresSafeArea()
            
            // Game Objects
            PickableObject(
                position: pickablePosition,
                isHighlighted: visionProcessor.pickDetected
            )
            
            KickableBomb(
                position: bombPosition,
                isHighlighted: visionProcessor.kickDetected
            )
            
            // Score and Feedback
            VStack {
                ScoreView(pickCount: pickCount, kickCount: kickCount)
                
                if showFeedback {
                    Text(feedbackMessage)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(10)
                        .transition(.scale.combined(with: .opacity))
                }
                
                Spacer()
            }
            .padding()
        }
        .onChange(of: visionProcessor.pickDetected) { detected in
            if detected {
                checkPickGesture()
            }
        }
        .onChange(of: visionProcessor.kickDetected) { detected in
            if detected {
                checkKickGesture()
            }
        }
    }
    
    // MARK: - Game Logic
    private func checkPickGesture() {
        guard let thumbTip = visionProcessor.handLandmarks[.thumbTip] else { return }
        
        let screenThumb = visionProcessor.convertToScreenCoordinates(thumbTip, in: UIScreen.main.bounds)
        let distance = hypot(screenThumb.x - pickablePosition.x,
                           screenThumb.y - pickablePosition.y)
        
        if distance < interactionRadius {
            pickCount += 1
            showFeedback(message: "Great Pick! +1")
            movePickableToNewPosition()
        }
    }
    
    private func checkKickGesture() {
        guard let ankle = visionProcessor.bodyLandmarks[.rightAnkle] else { return }
        
        let screenAnkle = visionProcessor.convertToScreenCoordinates(ankle, in: UIScreen.main.bounds)
        let distance = hypot(screenAnkle.x - bombPosition.x,
                           screenAnkle.y - bombPosition.y)
        
        if distance < interactionRadius {
            kickCount += 1
            showFeedback(message: "Nice Kick! +1")
            moveBombToNewPosition()
        }
    }
    
    private func movePickableToNewPosition() {
        withAnimation(.easeInOut(duration: 0.3)) {
            pickablePosition = generateNewPosition()
        }
    }
    
    private func moveBombToNewPosition() {
        withAnimation(.easeInOut(duration: 0.3)) {
            bombPosition = generateNewPosition()
        }
    }
    
    private func generateNewPosition() -> CGPoint {
        CGPoint(
            x: CGFloat.random(in: minX...maxX),
            y: CGFloat.random(in: minY...maxY)
        )
    }
    
    private func showFeedback(message: String) {
        feedbackMessage = message
        withAnimation(.easeInOut(duration: 0.3)) {
            showFeedback = true
        }
        
        // Hide feedback after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showFeedback = false
            }
        }
    }
} 