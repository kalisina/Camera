//
//  CameraCapture.swift
//  Camera
//
//  Created by Triumph on 22/03/2023.
//

import AVFoundation
import CoreImage

class CameraCapture: NSObject {
    
    var cameraPostion: AVCaptureDevice.Position
    
    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.triumph.SessionQ")
    private let videoOutput = AVCaptureVideoDataOutput()
    
    init(cameraPostion: AVCaptureDevice.Position) {
        self.cameraPostion = cameraPostion
        super.init()
        
        checkPermissions()
        sessionQueue.async {
            self.prepareSession()
            self.startSession()
        }
    }
    
    deinit {
        print("cameraCapture deinit")
        stopSession()
    }
    
    func startSession() {
        if !session.isRunning {
            DispatchQueue.global().async {
                self.session.startRunning()
            }
        }
    }
    
    func stopSession() {
        if session.isRunning {
            DispatchQueue.global().async {
                self.session.stopRunning()
            }
        }
    }
    
    private func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: .video) { authorized in
                self.sessionQueue.resume()
            }
        case .restricted: break
        case .denied: break
        case .authorized: break
        @unknown default: break
        }
    }
    
    private func prepareSession() {
        session.beginConfiguration()
        
        defer {
            session.commitConfiguration()
        }
        
        let cameraDiscovery = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInTripleCamera, .builtInDualCamera, .builtInWideAngleCamera], mediaType: .video, position: .back)
        
        guard let camera = cameraDiscovery.devices.first,
              let input = try? AVCaptureDeviceInput(device: camera) else {
            fatalError("Can't get hold of the camera")
        }
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
            
        }
        
        session.sessionPreset = .hd4K3840x2160
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        
        let videoConnection = videoOutput.connection(with: .video)
        videoConnection?.videoOrientation = .portrait
        
        do {
            try camera.lockForConfiguration()
            camera.videoZoomFactor = 2.0
            camera.unlockForConfiguration()
        } catch {
            print("videoDevice lockForConfiguration returned error \(error)")
        }
    }
    
    func set(_ delegate: AVCaptureVideoDataOutputSampleBufferDelegate, queue: DispatchQueue) {
        sessionQueue.async {
            self.videoOutput.setSampleBufferDelegate(delegate, queue: queue)
        }
    }
}

