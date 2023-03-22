//
//  CGImage+Extension.swift
//  Camera
//
//  Created by Triumph on 22/03/2023.
//

import CoreGraphics
import VideoToolbox

extension CGImage {
    
    static func create(from cvPixelBuffer: CVPixelBuffer?) -> CGImage? {
        guard let pixelBuffer = cvPixelBuffer else { return nil }
        var image: CGImage?
        VTCreateCGImageFromCVPixelBuffer(
            pixelBuffer,
            options: nil,
            imageOut: &image)
        return image
    }
}
