import SwiftUI
import AVFoundation

struct CameraView: UIViewControllerRepresentable {
    let onFrame: (CMSampleBuffer) -> Void
    
    class Coordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
        let parent: CameraView
        
        init(parent: CameraView) {
            self.parent = parent
        }
        
        func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            parent.onFrame(sampleBuffer)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        
        // Set up camera session
        let session = AVCaptureSession()
        session.sessionPreset = .high
        
        // Configure camera input
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: device) else {
            return viewController
        }
        
        session.addInput(input)
        
        // Configure video output
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(context.coordinator, queue: DispatchQueue(label: "videoQueue"))
        session.addOutput(videoOutput)
        
        // Configure preview layer
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = UIScreen.main.bounds
        viewController.view.layer.addSublayer(previewLayer)
        
        // Start capture session
        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
        
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // No updates needed
    }
} 