//
//  ContentView.swift
//  ImmersiveUI
//
//  Created by 강동영 on 6/8/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject var motion = MotionManager()
    var pitch: String {
        String(format: "%0.4f", motion.pitch)
    }
    
    var roll: String {
        String(format: "%0.4f", motion.roll)
    }
    let buttonSize = CGSize(width: 250, height: 250) // 버튼 크기 정의

    var body: some View {
        VStack(alignment: .leading) {
            Text("tiltX: \(pitch)")
            Text("tiltY: \(roll)")
        }
        
        ZStack {
            MetalButtonView(motion: motion, size: buttonSize)
                .frame(width: buttonSize.width, height: buttonSize.height)
            Text("Hello, World !")
                .foregroundColor(Color.white)
                .rotation3DEffect(
                    .degrees(motion.pitch * 20),
                    axis: (x: 1, y: 0, z: 0))
                .rotation3DEffect(
                    .degrees(motion.roll * 20),
                    axis: (x: 0, y: 1, z: 0))
//                .drawingGroup(opaque: false, colorMode: .extendedLinear)
        }
    }
}

struct MetalBackgroundViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.background(MetalBackground())
    }
}

struct MetalBackground: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
//        view.layer.wantsExtendedDynamicRangeContent = true
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
