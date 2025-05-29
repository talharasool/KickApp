import Vision
import UIKit
import SwiftUI

class VisionProcessor: ObservableObject {
    // MARK: - Published Properties
    @Published var pickDetected = false
    @Published var kickDetected = false
    @Published var handLandmarks: [VNHumanHandPoseObservation.JointName: CGPoint] = [:]
    @Published var bodyLandmarks: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
    
    // MARK: - Vision Requests
    private let handPoseRequest: VNDetectHumanHandPoseRequest
    private let bodyPoseRequest: VNDetectHumanBodyPoseRequest
    private let visionQueue = DispatchQueue(label: "com.tasleem.vision", qos: .userInteractive)
    
    // MARK: - Gesture Thresholds
    private let pickThreshold: Float = 0.08  // More sensitive pick detection
    private let kickThreshold: Float = 0.15   // More sensitive kick detection
    private let confidenceThreshold: Float = 0.3
    
    init() {
        handPoseRequest = VNDetectHumanHandPoseRequest()
        bodyPoseRequest = VNDetectHumanBodyPoseRequest()
        
        // Configure requests for better performance
        handPoseRequest.maximumHandCount = 1
        
    }
    
    func processFrame(_ sampleBuffer: CMSampleBuffer) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: imageBuffer, orientation: .leftMirrored, options: [:])
        
        visionQueue.async {
            do {
                try handler.perform([self.handPoseRequest, self.bodyPoseRequest])
                self.processHandPose()
                self.processBodyPose()
            } catch {
                print("Vision error: \(error)")
                DispatchQueue.main.async {
                    self.pickDetected = false
                    self.kickDetected = false
                }
            }
        }
    }
    
    private func processHandPose() {
        guard let handPose = handPoseRequest.results?.first else {
            DispatchQueue.main.async { self.pickDetected = false }
            return
        }
        
        do {
            let thumbTip = try handPose.recognizedPoint(.thumbTip)
            let indexTip = try handPose.recognizedPoint(.indexTip)
            
            guard thumbTip.confidence > confidenceThreshold && indexTip.confidence > confidenceThreshold else {
                DispatchQueue.main.async { self.pickDetected = false }
                return
            }
            
            let distance = hypot(thumbTip.location.x - indexTip.location.x,
                               thumbTip.location.y - indexTip.location.y)
            
            DispatchQueue.main.async {
                self.handLandmarks = [
                    .thumbTip: thumbTip.location,
                    .indexTip: indexTip.location
                ]
                
                // Smooth the pick detection to avoid flickering
                withAnimation(.easeInOut(duration: 0.1)) {
                    self.pickDetected = distance < CGFloat(self.pickThreshold)
                }
            }
        } catch {
            print("Hand pose error: \(error)")
            DispatchQueue.main.async { self.pickDetected = false }
        }
    }
    
    private func processBodyPose() {
        guard let bodyPose = bodyPoseRequest.results?.first else {
            DispatchQueue.main.async { self.kickDetected = false }
            return
        }
        
        do {
            let ankle = try bodyPose.recognizedPoint(.rightAnkle)
            let knee = try bodyPose.recognizedPoint(.rightKnee)
            let hip = try bodyPose.recognizedPoint(.rightHip)
            
            guard ankle.confidence > confidenceThreshold && 
                  knee.confidence > confidenceThreshold && 
                  hip.confidence > confidenceThreshold else {
                DispatchQueue.main.async { self.kickDetected = false }
                return
            }
            
            // Enhanced kick detection logic
            let isKicking = ankle.location.y < knee.location.y - CGFloat(kickThreshold) &&
                          ankle.location.y < hip.location.y - CGFloat(kickThreshold)
            
            DispatchQueue.main.async {
                self.bodyLandmarks = [
                    .rightAnkle: ankle.location,
                    .rightKnee: knee.location,
                    .rightHip: hip.location
                ]
                
                // Smooth the kick detection to avoid flickering
                withAnimation(.easeInOut(duration: 0.1)) {
                    self.kickDetected = isKicking
                }
            }
        } catch {
            print("Body pose error: \(error)")
            DispatchQueue.main.async { self.kickDetected = false }
        }
    }
    
    // MARK: - Coordinate Conversion
    func convertToScreenCoordinates(_ point: CGPoint, in bounds: CGRect) -> CGPoint {
        // Convert normalized coordinates (0...1) to screen coordinates
        // Note: Vision coordinates are in bottom-left origin system
        return CGPoint(
            x: point.x * bounds.width,
            y: (1 - point.y) * bounds.height
        )
    }
} 
