//
//  CameraCapture.swift
//  Camera
//
//  Created by Triumph on 22/03/2023.
//

import AVFoundation
import CoreImage

class CameraCapture: NSObject {
    typealias Callback = (CIImage?) -> ()
    
    let cameraPostion: AVCaptureDevice.Position
    let callback: Callback
    
    private let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    
    init(cameraPostion: AVCaptureDevice.Position, callback: @escaping Callback) {
        self.cameraPostion = cameraPostion
        self.callback = callback
        
        super.init()
        
        prepareSession()
    }
    
    private func prepareSession() {
        session.sessionPreset = .hd4K3840x2160
        
        let cameraDiscovery = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInTripleCamera, .builtInDualCamera, .builtInWideAngleCamera], mediaType: .video, position: .back)
        
        guard let camera = cameraDiscovery.devices.first,
              let input = try? AVCaptureDeviceInput(device: camera) else {
            fatalError("Can't get hold of the camera")
        }
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        let output = AVCaptureVideoDataOutput()
    }
}


