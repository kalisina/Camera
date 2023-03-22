//
//  ViewModel.swift
//  Camera
//
//  Created by Triumph on 22/03/2023.
//

import Foundation
import SwiftUI

class ViewModel: ObservableObject {
    
    @Published var frame: CGImage?
    
    var frameManager: FrameManager
    
    init(frameManager: FrameManager) {
        self.frameManager = frameManager
        setupSubscriptions()
    }
    
    func setupSubscriptions() {
        frameManager.$current
            .receive(on: RunLoop.main)
            .compactMap({ pixelBuffer in
                return CGImage.create(from: pixelBuffer)
            })
            .assign(to: &$frame)
    }
}
