//
//  GlowingWavesView.swift
//  Lagoon
//
//  Metal-based glowing waves animation
//

import SwiftUI
import MetalKit

struct GlowingWavesView: UIViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.delegate = context.coordinator
        mtkView.preferredFramesPerSecond = 60
        mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        mtkView.layer.isOpaque = false
        return mtkView
    }

    func updateUIView(_ uiView: MTKView, context: Context) {}

    class Coordinator: NSObject, MTKViewDelegate {
        var parent: GlowingWavesView
        var device: MTLDevice!
        var commandQueue: MTLCommandQueue!
        var pipelineState: MTLRenderPipelineState!
        var startTime: CFAbsoluteTime!

        init(_ parent: GlowingWavesView) {
            self.parent = parent
            super.init()

            self.device = MTLCreateSystemDefaultDevice()
            self.commandQueue = self.device.makeCommandQueue()
            self.pipelineState = buildPipelineState(device: self.device)
            self.startTime = CFAbsoluteTimeGetCurrent()
        }

        func buildPipelineState(device: MTLDevice) -> MTLRenderPipelineState? {
            guard let library = device.makeDefaultLibrary(),
                  let vertexFunction = library.makeFunction(name: "waveVertexShader"),
                  let fragmentFunction = library.makeFunction(name: "waveFragmentShader") else {
                return nil
            }

            let pipelineDescriptor = MTLRenderPipelineDescriptor()
            pipelineDescriptor.vertexFunction = vertexFunction
            pipelineDescriptor.fragmentFunction = fragmentFunction
            pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
            pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
            pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha

            return try? device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        }

        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

        func draw(in view: MTKView) {
            guard let drawable = view.currentDrawable,
                  let descriptor = view.currentRenderPassDescriptor,
                  let pipelineState = pipelineState else { return }

            let commandBuffer = commandQueue.makeCommandBuffer()!
            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)!

            renderEncoder.setRenderPipelineState(pipelineState)

            var time = Float(CFAbsoluteTimeGetCurrent() - self.startTime)
            var resolution = vector_float2(Float(view.drawableSize.width), Float(view.drawableSize.height))

            renderEncoder.setVertexBytes(&resolution, length: MemoryLayout<vector_float2>.size, index: 1)
            renderEncoder.setFragmentBytes(&time, length: MemoryLayout<Float>.size, index: 0)

            renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
            renderEncoder.endEncoding()

            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
}
