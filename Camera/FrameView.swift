//
//  FrameView.swift
//  Camera
//
//  Created by Triumph on 22/03/2023.
//

import SwiftUI

struct FrameView: View {
  
  var image: CGImage?
  private let label = Text("Camera feed")
  
  var body: some View {

    if let image = image {
      GeometryReader { geometry  in
        Image(image, scale: 1.0, orientation: .up, label: label)
          .resizable()
          .scaledToFill()
          .frame(
            width: geometry.size.width,
            height: geometry.size.height,
            alignment: .center)
          .clipped()
      }
    } else {
      EmptyView()
    }
  }
}

struct FrameView_Previews: PreviewProvider {
    static var previews: some View {
        FrameView(image: nil)
    }
}
