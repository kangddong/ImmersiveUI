//
// MetalButtonView.swift
//  ImmersiveUI
//
//  Created by 강동영 on 6/8/25.
//

import SwiftUI
import MetalKit
import simd

struct Uniforms {
    var pitch: Float
    var roll: Float
    var resolution: simd_float2
}

struct MetalButtonView: UIViewRepresentable {
    @ObservedObject var motion: MotionManager
    var size: CGSize

    func makeCoordinator() -> Renderer {
        Renderer(motion: motion, size: size)
    }

    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()

        if let metalDevice = MTLCreateSystemDefaultDevice() {
            mtkView.device = metalDevice
        }
        
        mtkView.delegate = context.coordinator
        mtkView.preferredFramesPerSecond = 60
        mtkView.enableSetNeedsDisplay = true

        mtkView.framebufferOnly = false
        mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        mtkView.isPaused = false
        return mtkView
    }

    func updateUIView(_ uiView: MTKView, context: Context) {
        context.coordinator.updateMotionData(pitch: motion.pitch, roll: motion.roll)
        context.coordinator.updateSize(size)
        
        let newDrawableSize = CGSize(width: size.width * uiView.contentScaleFactor,
                                     height: size.height * uiView.contentScaleFactor)
        if uiView.drawableSize != newDrawableSize {
            uiView.drawableSize = newDrawableSize
        }
        uiView.setNeedsDisplay()
    }
}

class Renderer: NSObject, MTKViewDelegate {
    var metalDevice: MTLDevice!
    var metalCommandQueue: MTLCommandQueue!
    var renderPipelineState: MTLRenderPipelineState!
    var vertexBuffer: MTLBuffer!

    var uniforms: Uniforms // 타입 어노테이션만 사용, 초기화는 init에서
    var viewSize: CGSize = .zero // 포인트 단위 크기

    let vertices: [Float] = [
        -0.8, -0.8,
         0.8, -0.8,
        -0.8,  0.8,
        -0.8,  0.8,
         0.8, -0.8,
         0.8,  0.8
    ]

    init(motion: MotionManager, size: CGSize) {
        self.uniforms = Uniforms(pitch: Float(motion.pitch),
                                 roll: Float(motion.roll),
                                 resolution: simd_float2(Float(size.width * UIScreen.main.scale), Float(size.height * UIScreen.main.scale)))
        self.viewSize = size // 포인트 단위 크기 저장
        
        super.init()

        guard let metalDevice = MTLCreateSystemDefaultDevice() else {
            fatalError()
        }
        self.metalDevice = metalDevice
        self.metalCommandQueue = metalDevice.makeCommandQueue()

        let vertexDataSize = vertices.count * MemoryLayout<Float>.size
        vertexBuffer = metalDevice.makeBuffer(bytes: vertices, length: vertexDataSize, options: [])

        guard let defaultLibrary = metalDevice.makeDefaultLibrary() else {
             fatalError("Could not load default Metal library")
        }
        let vertexFunction = defaultLibrary.makeFunction(name: "vertex_shader")
        let fragmentFunction = defaultLibrary.makeFunction(name: "fragment_shader")

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha

        do {
            renderPipelineState = try metalDevice.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            fatalError("Failed to create render pipeline state: \(error)")
        }
    }

    func updateMotionData(pitch: Double, roll: Double) {
        self.uniforms.pitch = Float(pitch)
        self.uniforms.roll = Float(roll)
    }
    
    func updateSize(_ newSize: CGSize) {
        self.viewSize = newSize
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        self.uniforms.resolution = simd_float2(Float(size.width), Float(size.height))
    }

    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let renderPassDescriptor = view.currentRenderPassDescriptor else {
            return
        }
        
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)

        guard let commandBuffer = metalCommandQueue.makeCommandBuffer(),
              let renderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }

        renderCommandEncoder.setRenderPipelineState(renderPipelineState)
        renderCommandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        var currentUniforms = self.uniforms

        renderCommandEncoder.setFragmentBytes(&currentUniforms, length: MemoryLayout<Uniforms>.stride, index: 0)

        renderCommandEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertices.count / 2)
        renderCommandEncoder.endEncoding()

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
