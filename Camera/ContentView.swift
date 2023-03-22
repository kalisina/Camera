//
//  ContentView.swift
//  Camera
//
//  Created by Triumph on 22/03/2023.
//

import SwiftUI

struct ContentView: View {
    
    @StateObject private var vm = ViewModel(frameManager: FrameManager())
    
    var body: some View {
        ZStack {
            FrameView(image: vm.frame).edgesIgnoringSafeArea(.all)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
