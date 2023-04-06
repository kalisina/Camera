//
//  ContentView.swift
//  Camera
//
//  Created by Triumph on 22/03/2023.
//

import SwiftUI

struct ContentView: View {
    
    @StateObject private var vm = ViewModel(frameManager: FrameManager())
    
    @GestureState private var isDetectingLongPress = false
    @State private var completedLongPress = false
    @State private var offset = CGSize.zero
    @State private var dragAmount = CGSize.zero
    @State private var burstModeEnabled: Bool = false
    @State private var burstCounterOpacity: Double = 0.0
    @State private var sliderValue : Float = 0.0
    
    
    var longPress: some Gesture {
        LongPressGesture(minimumDuration: 10, maximumDistance: 200)
            .updating($isDetectingLongPress) { currentState, gestureState,
                transaction in
                gestureState = currentState
                transaction.animation = Animation.easeIn(duration: 2.0)
                print("LongPress updating")
            }
            .onEnded { finished in
                self.completedLongPress = finished
                print("LongPress onEnded")
            }
    }
    
    var body: some View {
        ZStack {
            FrameView(image: vm.frame).edgesIgnoringSafeArea(.all)
            
            Text(vm.stopWatchTimer)
                .font(.title)
                .foregroundColor(.white)
                .opacity(burstCounterOpacity)
            
            VStack {
                
                
                Text(vm.cameraLens)
                
                VStack {
                    Text("Current Slider Value: \(Int(sliderValue))")
                    
                    Slider(value: $sliderValue, in: 0...10, step: 1) {
                        Text("Slider")
                    } minimumValueLabel: {
                        Text("0").font(.title2).fontWeight(.thin)
                    } maximumValueLabel: {
                        Text("10").font(.title2).fontWeight(.thin)
                    } onEditingChanged: { newValue in
                        vm.sliderSubject.send(sliderValue)
                    }
                }
                    
                       
    
                
                
                
                Spacer()
                ZStack {
                    Circle()
                        .inset(by: 0)
                        .stroke(burstModeEnabled ? .yellow : .white, lineWidth: 5)
                        .frame(width: 70, height: 70)
                    
                    Circle()
                        .fill(burstModeEnabled ? .yellow : .white)
                        .frame(width: 45, height: 45)
                        .offset(dragAmount)
                        .simultaneousGesture(TapGesture().onEnded {
                            print("Boring regular tap")
                            //vm.singleTap()
                        })
                        .pressAction { val in
                            dragAmount = val.translation
                            
                            if val.translation.width < -100.0 ||
                                val.translation.width > 100.0 ||
                                val.translation.height < -100.0 {
                                vm.startTimer()
                                withAnimation {
                                    burstModeEnabled = true
                                    burstCounterOpacity = 1.0
                                }
                                
                            } else {
                                vm.stopTimer()
                                withAnimation {
                                    burstModeEnabled = false
                                }
                            }
                            //vm.burstButtonOnChanged()
                        } onRelease: {
                            print("onRelease")
                            vm.stopTimer()
                            withAnimation {
                                dragAmount = .zero
                                burstModeEnabled = false
                                burstCounterOpacity = 0.0
                            }
                        }
                    
                    Text(String(describing: vm.burstCounter))
                        .foregroundColor(.white)
                        .font(.title)                        
                        .opacity(burstCounterOpacity)
                    
                }
            }
        }
        .onTapGesture { location in
            //print("location =", location)
            // I should use combine here
            vm.setFocusAtLocation(location)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
