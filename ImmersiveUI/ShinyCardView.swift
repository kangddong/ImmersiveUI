//
//  ShinyCardView.swift
//  ImmersiveUI
//
//  Created by 강동영 on 6/9/25.
//

import SwiftUI

struct ShinyCardView: View {
    @State var transition: CGSize = .zero
    @State var isDragging = false
    @State var tap = false
    @GestureState var press = false
    
    var longPress: some Gesture {
        LongPressGesture(minimumDuration: 3)
            .updating($press) { currentState, gestureState, transaction in
                gestureState = currentState
                transaction.animation = .spring
            }
    }
    
    var drag: some Gesture {
        DragGesture()
            .onChanged { value in
                transition = value.translation
                isDragging = true
            }
            .onEnded { value in
                withAnimation {
                    transition = .zero
                    isDragging = false
                }
            }
    }
    
    var body: some View {
        ZStack {
            Color(#colorLiteral(red: 0.1599538828, green: 0.1648334563, blue: 0.1861925721, alpha: 1)).ignoresSafeArea()
            
            Image(systemName: "")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 600)
                .frame(maxWidth: 390)
                .overlay(CameraView().scaleEffect(1.5).blur(radius: 10))
                .overlay {
                    ZStack {
                        Image(systemName: "")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100)
                            .offset(x: transition.width/8, y: transition.height/15)
                        Image(systemName: "")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 400)
                            .offset(x: transition.width/10, y: transition.height/20)
                        Image(systemName: "")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100)
                            .offset(x: transition.width/8, y: transition.height/15)
                    }
                }
        }
    }
}

#Preview {
    ShinyCardView()
}
