//
//  FrameManager.swift
//  Camera
//
//  Created by Triumph on 22/03/2023.
//

import AVFoundation
import PhotosUI

class FrameManager: NSObject, ObservableObject {
    
    @Published var current: CVPixelBuffer?
    @Published var numberOfPhotoCaptured: Int = 0
    @Published var cameraLens: String = ""
    
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
    
    func capturePhoto() {
        cameraCapture.capturePhoto(self)
    }
    
    func captureBurstPhoto() {
        cameraCapture.captureBurstPhoto(self)
    }
    
    func setFocusAtLocation(_ location: CGPoint) {
        cameraCapture.setFocus(focusMode: .autoFocus, exposureMode: .autoExpose, atPoint: location, shouldMonitorSubjectAreaChange: true)
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
            //self.cameraLens = output.connections.first?.description ?? ""
            self.cameraLens = output.connections.first?.inputPorts.first?.input.description ?? ""
        }
    }
}

extension FrameManager: AVCapturePhotoCaptureDelegate {
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let _ = error {
            return
        }
        guard let photo = photo.fileDataRepresentation() else { return }
        numberOfPhotoCaptured+=1
        print("numberOfPhotoCaptured = \(numberOfPhotoCaptured)")
        
        // Copy the file to the Photo Library
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                PHPhotoLibrary.shared().performChanges {
                    let request = PHAssetCreationRequest.forAsset()
                    request.addResource(with: .photo, data: photo, options: nil)
                } completionHandler: { succes, error in
                    //print("succes = ", succes, "error = ", error?.localizedDescription ?? "no error")
                }
            }
        }
    }
}
