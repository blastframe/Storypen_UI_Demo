import SwiftUI
import MetalKit

/// Wraps `MTKView` in a SwiftUI view. Currently renders a solid clear-color pass
/// as a Metal-ready stub for the drawing pipeline.
struct MetalCanvasView: UIViewRepresentable {
    @Environment(\.colorScheme) private var colorScheme

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> MTKView {
        let view = MTKView()
        view.device                   = MTLCreateSystemDefaultDevice()
        view.clearColor               = clearColor
        view.colorPixelFormat         = .bgra8Unorm
        view.enableSetNeedsDisplay    = false
        view.isPaused                 = false
        view.preferredFramesPerSecond = 60
        view.delegate                 = context.coordinator
        return view
    }

    func updateUIView(_ uiView: MTKView, context: Context) {
        uiView.clearColor = clearColor
    }

    private var clearColor: MTLClearColor {
        colorScheme == .dark ? AppTheme.canvasDark : AppTheme.canvasLight
    }

    // MARK: – Coordinator / MTKViewDelegate

    final class Coordinator: NSObject, MTKViewDelegate {
        private var commandQueue: MTLCommandQueue?

        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            if commandQueue == nil {
                commandQueue = view.device?.makeCommandQueue()
            }
        }

        func draw(in view: MTKView) {
            guard
                let drawable   = view.currentDrawable,
                let descriptor = view.currentRenderPassDescriptor,
                let device     = view.device
            else { return }

            if commandQueue == nil { commandQueue = device.makeCommandQueue() }

            guard
                let queue  = commandQueue,
                let buffer = queue.makeCommandBuffer(),
                let encoder = buffer.makeRenderCommandEncoder(descriptor: descriptor)
            else { return }

            encoder.endEncoding()
            buffer.present(drawable)
            buffer.commit()
        }
    }
}
