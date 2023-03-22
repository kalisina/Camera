//
//  FrameManager.swift
//  Camera
//
//  Created by Triumph on 22/03/2023.
//

import AVFoundation

class FrameManager: NSObject, ObservableObject {
    
    @Published var current: CVPixelBuffer?
    var cameraCapture: CameraCapture
    
    let videoOutputQueue = DispatchQueue(
        label: "com.triumph.VideoOutputQ",
        qos: .userInitiated,
        attributes: [],
        autoreleaseFrequency: .workItem)
    
    override init() {
        cameraCapture = CameraCapture(cameraPostion: .back)
        super.init()
        
        cameraCapture.set(self, queue: videoOutputQueue)        
    }
    
    deinit {
        print("FrameManager deinit")
    }
}

extension FrameManager: AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {        
        guard let imageBuffer = sampleBuffer.imageBuffer else { return }
        DispatchQueue.main.async {
            self.current = imageBuffer
        }
    }
}
