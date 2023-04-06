//
//  ViewModel.swift
//  Camera
//
//  Created by Triumph on 22/03/2023.
//

import Foundation
import SwiftUI
import Combine

class ViewModel: ObservableObject {
    
    @Published var frame: CGImage?
    @Published var burstCounter: Int = 0
    @Published var stopWatchTimer: String = ""
    @Published var cameraLens: String = ""
    
    var cancellables = Set<AnyCancellable>()
    let timerPublisher = Timer.TimerPublisher(interval: 0.1, runLoop: .main, mode: .common)
    var timerCancellable: AnyCancellable?
    
    let sliderSubject = PassthroughSubject<Float, Never>()
    var sliderPublisher: AnyPublisher<Float, Never> {
        return sliderSubject.eraseToAnyPublisher()
    }
    
    var frameManager: FrameManager
    
    init(frameManager: FrameManager) {
        self.frameManager = frameManager
        setupSubscriptions()
        setupSubscriptionsOnInternalProperties()
    }
    
    func setupSubscriptions() {
        frameManager.$current
            .receive(on: RunLoop.main)
            .compactMap({ pixelBuffer in
                return CGImage.create(from: pixelBuffer)
            })
            .assign(to: &$frame)
        
        frameManager.$numberOfPhotoCaptured
            .receive(on: RunLoop.main)
            .sink { [weak self]  cpt in
                self?.burstCounter = cpt
            }
            .store(in: &cancellables)
        
        frameManager.$cameraLens
            .receive(on: RunLoop.main)
            .sink { [weak self]  valueReceived in
                self?.cameraLens = valueReceived
            }
            .store(in: &cancellables)
    }
    
    func setupSubscriptionsOnInternalProperties() {
        
        sliderPublisher
            .map({ $0 / 10 })
            .sink { [weak self] val in
                print("val = ", val)
                self?.frameManager.cameraCapture.changeLensPosition(val)
                
            }
            .store(in: &cancellables)
    }
    
    
    func singleTap() {
        frameManager.capturePhoto()
    }
    
    func setFocusAtLocation(_ location: CGPoint) {        
        frameManager.setFocusAtLocation(location)
    }
}

extension ViewModel {
    
    func startTimer() {
        if timerCancellable != nil { return }
        print("startTimer should be called only once")
        let startTime = Date.now
        timerCancellable = timerPublisher
            .autoconnect()
            .receive(on: RunLoop.main)
            .sink { completion in
                print("completion = \(completion)")
            } receiveValue: { [weak self] date in
                self?.timeDifferenceBetweenStartDate(startTime, andEndDate: date)
                self?.frameManager.captureBurstPhoto()
            }
    }
    
    func stopTimer() {
        if timerCancellable != nil {
            print("timer exist, so cancel it")
            timerCancellable?.cancel()
            timerCancellable = nil
            frameManager.numberOfPhotoCaptured = 0
        }
    }
    
    func timeDifferenceBetweenStartDate(_ startDate: Date, andEndDate endDate: Date) {
        let diffSeconds = Int(endDate.timeIntervalSince1970 - startDate.timeIntervalSince1970)
        let diffMinutes = diffSeconds / 60
        let diffHours = diffSeconds / 3600
        
        let formattedSeconds = String(format: "%02d", diffSeconds % 60)
        let formattedMinutes = String(format: "%02d", diffMinutes)
        let formattedHours = String(format: "%02d", diffHours)
        
        stopWatchTimer = "\(formattedHours):\(formattedMinutes):\(formattedSeconds)"
        print(stopWatchTimer)
    }
}
