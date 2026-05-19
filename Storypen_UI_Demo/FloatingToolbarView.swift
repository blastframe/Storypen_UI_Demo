import SwiftUI

/// Draggable floating tool palette. Drag is restricted to the grabber at the top.
/// Live translation is self-contained; the parent receives the final delta via onDragEnded.
struct FloatingToolbarView: View {
    @Bindable var viewModel: ProjectEditorViewModel
    let onDragEnded: (CGSize) -> Void

    @GestureState private var liveTranslation: CGSize = .zero

    var body: some View {
        Group {
            if viewModel.usesMetalBackedRendering {
                toolbarBody.drawingGroup()
            } else {
                toolbarBody
            }
        }
        .offset(x: liveTranslation.width, y: liveTranslation.height)
    }

    private var toolbarBody: some View {
        VStack(spacing: 0) {
            // Grab handle — plain rect background + pill indicator, no border
            ZStack {
                AppTheme.surfaceBackground
                Capsule()
                    .fill(AppTheme.secondaryText.opacity(0.45))
                    .frame(width: 24, height: 4)
            }
            .frame(height: 30)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .global)
                    .updating($liveTranslation) { val, state, transaction in
                        state = val.translation
                        // Prevent any implicit animation from fighting the gesture recognizer.
                        transaction.animation = .none
                    }
                    .onEnded { val in
                        onDragEnded(val.translation)
                    }
            )
            .accessibilityLabel("Drag to reposition toolbar")

            AppTheme.divider.frame(height: 1)

            // Tool buttons — width driven by button frame (44 pt)
            VStack(spacing: 0) {
                ForEach(viewModel.tools) { tool in
                    Button {
                        viewModel.activeToolTitle = tool.title
                    } label: {
                        Image(systemName: tool.systemImage)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(
                                viewModel.activeToolTitle == tool.title
                                    ? AppTheme.actionOrange
                                    : AppTheme.secondaryText
                            )
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(tool.title)
                }
            }
            .padding(.bottom, 4)
        }
        .fixedSize(horizontal: true, vertical: false)
        .background(AppTheme.surfaceBackground)
    }
}
