//
//  PressAction.swift
//  Camera
//
//  Created by Triumph on 27/03/2023.
//

import SwiftUI

struct PressActions: ViewModifier {
    
    var onPress: (DragGesture.Value) -> Void
    var onRelease: () -> Void
    
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged({ val in
                        onPress(val)
                    })
                    .onEnded({ val in                        
                        onRelease()
                    })
            )
    }
}

extension View {
    func pressAction(onPress: @escaping ((DragGesture.Value) -> Void), onRelease: @escaping (() -> Void)) -> some View {
        modifier(PressActions(onPress: { val in
            onPress(val)
        }, onRelease: {
            onRelease()
        }))
    }
}
