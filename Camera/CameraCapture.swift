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
    private let videoOutput = AVCaptureVideoDataOutput() // for the video
    private let photoOutput = AVCapturePhotoOutput()
    private var deviceInput: AVCaptureDeviceInput?
    private var cameraDevice: AVCaptureDevice?
    
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
        
        /*let cameraDiscovery = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInTripleCamera, .builtInDualCamera, .builtInWideAngleCamera], mediaType: .video, position: .back)*/
        
        //let deviceTypes2: [AVCaptureDevice.DeviceType] = [AVCaptureDevice.DeviceType.builtInWideAngleCamera, AVCaptureDevice.DeviceType.builtInDualCamera, AVCaptureDevice.DeviceType.builtInTelephotoCamera]
        
        let deviceTypes: [AVCaptureDevice.DeviceType] = [/*.builtInTripleCamera, .builtInDualWideCamera, .builtInDualCamera,*/ .builtInWideAngleCamera]
        
        let cameraDiscovery = AVCaptureDevice.DiscoverySession(deviceTypes: deviceTypes, mediaType: .video, position: .back)
        
        guard let camera = cameraDiscovery.devices.first,
              let input = try? AVCaptureDeviceInput(device: camera) else {
            fatalError("Can't get hold of the camera")
        }
        
        cameraDevice = camera
        deviceInput = input
        
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
        
        if ((videoConnection?.isVideoStabilizationSupported) != nil) {
            videoConnection?.preferredVideoStabilizationMode = .off
        }
        
        // Disable AutoFocus
        if input.device.isSmoothAutoFocusSupported {
            do {
                try input.device.lockForConfiguration()
                input.device.isSmoothAutoFocusEnabled = false
                input.device.focusMode = .locked
                print("disabling smooth autofocus and setting focusMode to ", input.device.focusMode.rawValue)
                input.device.unlockForConfiguration()
            } catch {
                print("error", error.localizedDescription)
            }
        }
        
        
        // Set Zoom Level to 1x
        do {
            try camera.lockForConfiguration()
            camera.videoZoomFactor = 2.0
            camera.unlockForConfiguration()
        } catch {
            print("videoDevice lockForConfiguration returned error \(error)")
        }
        
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }
    }
    
    func set(_ delegate: AVCaptureVideoDataOutputSampleBufferDelegate, queue: DispatchQueue) {
        sessionQueue.async {
            self.videoOutput.setSampleBufferDelegate(delegate, queue: queue)
        }
    }
    
    public func capturePhoto(_ delegate: AVCapturePhotoCaptureDelegate) {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: delegate)
    }
    
    public func captureBurstPhoto(_ delegate: AVCapturePhotoCaptureDelegate) {
        let settings = AVCapturePhotoSettings()
        settings.photoQualityPrioritization = .speed
        photoOutput.capturePhoto(with: settings, delegate: delegate)
    }
    
    func setFocus(focusMode: AVCaptureDevice.FocusMode,
                  exposureMode: AVCaptureDevice.ExposureMode,
                  atPoint devicePoint: CGPoint,
                  shouldMonitorSubjectAreaChange: Bool) {
        
        
        self.sessionQueue.async {
            guard let device = self.deviceInput?.device else { return }
            
            do {
                try device.lockForConfiguration()
                
                // set the focus point to the tapped area
                if device.isFocusPointOfInterestSupported, device.isFocusModeSupported(focusMode) {
                    device.focusPointOfInterest = devicePoint // this is only doable for .autoFocus
                    device.focusMode = focusMode
                } else {
                    print("isFocusPointOfInterestSupported = ", false)
                    print("device.isFocusModeSupported(\(focusMode)", false)
                }
                
                /*
                if device.isExposurePointOfInterestSupported, device.isExposureModeSupported(exposureMode) {
                    device.exposurePointOfInterest = devicePoint
                    device.exposureMode = exposureMode
                } else {
                 print("Manual exposure mode not supported.")
                 }
                 */
                
                
                if device.isExposureModeSupported(.locked) {
                    let minDuration = device.activeFormat.minExposureDuration
                    let maxDuration = device.activeFormat.maxExposureDuration
                    
                    // Set faster shutter speed (shorter exposure duration)
                    let desiredDuration = minDuration // Set to the minimum exposure duration
                    
                    if minDuration <= desiredDuration && desiredDuration <= maxDuration {
                        device.setExposureModeCustom(duration: desiredDuration, iso: AVCaptureDevice.currentISO, completionHandler: nil)
                    } else {
                        print("Desired shutter speed not within the supported range.")
                    }
                } else {
                    print("Manual exposure mode not supported.")
                }
                
                 
                device.isSubjectAreaChangeMonitoringEnabled = shouldMonitorSubjectAreaChange                                  
                device.unlockForConfiguration()
            } catch {
                print("error", error.localizedDescription)
            }
        }
    }
    
    func changeLensPosition(_ value: Float) {
        
        /*guard let cameraDevice = cameraDevice,
              let device = getWideAngleCamera(from: cameraDevice) else { return }*/
        
        
        guard let device = deviceInput?.device, device.isLockingFocusWithCustomLensPositionSupported else {
            print("isLockingFocusWithCustomLensPositionSupported = ", false)
            return
        }
         
        do {
            try device.lockForConfiguration()
            device.setFocusModeLocked(lensPosition: value, completionHandler: nil)
            print("Yes:")
            device.unlockForConfiguration()
        } catch let error {
            NSLog("Could not lock device for configuration: \(error)")
        }
    }
    
    func getWideAngleCamera(from tripleCamera: AVCaptureDevice) -> AVCaptureDevice? {
        return tripleCamera.constituentDevices.first { device in
            device.deviceType == .builtInWideAngleCamera
        }
    }
}

