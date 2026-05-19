import SwiftUI

struct CanvasWorkspaceRow: View {
    @Bindable var viewModel: ProjectEditorViewModel

    private let verticalDraggerWidth: CGFloat = 12

    var body: some View {
        GeometryReader { proxy in
            let maxPropsWidth    = min(viewModel.maxPropertiesPanelWidth, proxy.size.width * 0.55)
            let clampedPropsW    = viewModel.clampPropertiesPanelWidth(maxAllowed: maxPropsWidth)
            let expandedPanelW   = verticalDraggerWidth + clampedPropsW
            let animatedPanelW   = viewModel.isPropertiesPanelVisible ? expandedPanelW : 0
            let toolbarOffset = viewModel.clampedToolbarOffset(
                from: viewModel.toolbarOffset,
                to: proxy.size,
                panelWidth: animatedPanelW
            )
            let adjustmentsToolbarOffset = viewModel.clampedAdjustmentsToolbarOffset(
                from: viewModel.adjustmentsToolbarOffset,
                to: proxy.size,
                panelWidth: animatedPanelW
            )

            // alignment: .top ensures the properties panel header stays pinned
            // at the top of the container regardless of canvas-row height changes.
            HStack(alignment: .top, spacing: 0) {
                // ── Canvas Area ──────────────────────────────────────────
                ZStack(alignment: .topLeading) {
                    if viewModel.usesMetalBackedRendering {
                        MetalCanvasView()

                        CheckerboardView(squareSize: 28)
                            .opacity(0.18)
                            .allowsHitTesting(false)

                        CanvasOverlayGrid()
                            .allowsHitTesting(false)
                    } else {
                        CanvasRenderingDisabledView(project: viewModel.project)
                            .allowsHitTesting(false)
                    }

                    // Primary tools toolbar — drag restricted to grabber handle
                    FloatingToolbarView(viewModel: viewModel) { delta in
                        let proposedOffset = CGSize(
                            width:  toolbarOffset.width  + delta.width,
                            height: toolbarOffset.height + delta.height
                        )
                        viewModel.toolbarOffset = viewModel.clampedToolbarOffset(
                            from: proposedOffset,
                            to: proxy.size,
                            panelWidth: animatedPanelW
                        )
                    }
                    .offset(
                        x: toolbarOffset.width,
                        y: toolbarOffset.height
                    )

                    // Adjustments toolbar — drag restricted to grabber handle
                    FloatingAdjustmentsToolbarView(viewModel: viewModel) { delta in
                        let proposedOffset = CGSize(
                            width:  adjustmentsToolbarOffset.width  + delta.width,
                            height: adjustmentsToolbarOffset.height + delta.height
                        )
                        viewModel.adjustmentsToolbarOffset = viewModel.clampedAdjustmentsToolbarOffset(
                            from: proposedOffset,
                            to: proxy.size,
                            panelWidth: animatedPanelW
                        )
                    }
                    .offset(
                        x: adjustmentsToolbarOffset.width,
                        y: adjustmentsToolbarOffset.height
                    )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppTheme.canvasWell)

                // ── Properties Panel ─────────────────────────────────────
                HStack(alignment: .top, spacing: 0) {
                    VerticalDragger { delta in
                        viewModel.resizePropertiesPanel(deltaX: delta, maxAllowed: maxPropsWidth)
                    }
                    .frame(width: verticalDraggerWidth)
                    .frame(maxHeight: .infinity)

                    PropertiesPanelView(viewModel: viewModel)
                        .frame(width: clampedPropsW)
                        .frame(maxHeight: .infinity, alignment: .top)
                }
                .frame(width: animatedPanelW, alignment: .leading)
                .clipped()
                .background(AppTheme.surfaceBackground)
                .animation(.snappy(duration: 0.22, extraBounce: 0.0), value: viewModel.isPropertiesPanelVisible)
            }
            .onAppear {
                viewModel.placeAdjustmentsToolbarOnRightIfNeeded(in: proxy.size, panelWidth: animatedPanelW)
                viewModel.toolbarOffset = toolbarOffset
                viewModel.adjustmentsToolbarOffset = adjustmentsToolbarOffset
            }
            .onChange(of: proxy.size) { _, size in
                viewModel.placeAdjustmentsToolbarOnRightIfNeeded(in: size, panelWidth: animatedPanelW)
                viewModel.clampToolbarOffset(to: size, panelWidth: animatedPanelW)
                viewModel.clampAdjustmentsToolbarOffset(to: size, panelWidth: animatedPanelW)
            }
        }
    }
}

private struct CanvasRenderingDisabledView: View {
    let project: Project

    var body: some View {
        GeometryReader { proxy in
            let horizontalInset = max(32, proxy.size.width * 0.14)
            let availableWidth = max(120, proxy.size.width - horizontalInset * 2)
            let availableHeight = max(120, proxy.size.height - 80)
            let stageWidth = min(availableWidth, availableHeight * project.aspectRatio)
            let stageHeight = stageWidth / project.aspectRatio

            ZStack {
                AppTheme.canvasWell

                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(AppTheme.baseBackground)
                    .frame(width: stageWidth, height: stageHeight)
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(AppTheme.borderColor, lineWidth: 1)
                    }
                    .overlay {
                        VStack(spacing: 10) {
                            Text("CANVAS")
                                .font(AppTheme.structuralHeaderFont)
                                .tracking(1.4)
                                .foregroundStyle(AppTheme.secondaryText)

                            Text("Metal rendering disabled")
                                .font(AppTheme.bodyDenseSemiboldFont)
                                .foregroundStyle(AppTheme.primaryText)

                            Text("Toolbars remain active for drag testing.")
                                .font(AppTheme.bodyDenseFont)
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                        .padding(20)
                    }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: – Canvas Overlay

private struct CanvasOverlayGrid: View {
    var body: some View {
        GeometryReader { _ in
            Canvas { context, size in
                let step: CGFloat = 40
                var path = Path()

                stride(from: 0, through: size.width,  by: step).forEach { x in
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                }
                stride(from: 0, through: size.height, by: step).forEach { y in
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                }

                context.stroke(path, with: .color(AppTheme.borderColor), lineWidth: 1)
            }

            Text("METAL CANVAS")
                .font(AppTheme.structuralHeaderFont)
                .tracking(1.4)
                .foregroundStyle(AppTheme.secondaryText)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(AppTheme.surfaceBackground)
                .overlay { Rectangle().stroke(AppTheme.borderColor, lineWidth: 1) }
                .padding(10)
        }
    }
}
