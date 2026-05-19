import SwiftUI

/// Second independent floating toolbar: vertical Size/Strength sliders + Undo/Redo.
/// Drag is restricted to the grabber at the top.
struct FloatingAdjustmentsToolbarView: View {
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
            .accessibilityLabel("Drag to reposition adjustments toolbar")

            AppTheme.divider.frame(height: 1)

            // Sliders
            VStack(spacing: 10) {
                AdjustmentSlider(label: "SIZE",     value: $viewModel.brushSize)
                AdjustmentSlider(label: "STRENGTH", value: $viewModel.opacity)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 10)

            AppTheme.divider.frame(height: 1)

            // History
            VStack(spacing: 0) {
                HistoryButton(systemName: "arrow.uturn.backward", label: "Undo") {
                    viewModel.undoAction()
                }
                HistoryButton(systemName: "arrow.uturn.forward",  label: "Redo") {
                    viewModel.redoAction()
                }
            }
            .padding(.bottom, 4)
        }
        .fixedSize(horizontal: true, vertical: false)
        .background(AppTheme.surfaceBackground)
    }
}

// MARK: – Adjustment Slider

private struct AdjustmentSlider: View {
    let label: String
    @Binding var value: Double

    var body: some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.system(size: 10, weight: .bold, design: .default))
                .tracking(0.5)
                .foregroundStyle(AppTheme.secondaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(width: 56)

            VerticalSliderTrack(value: $value)

            Text("\(Int(value * 100))%")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(AppTheme.secondaryText)
                .monospacedDigit()
        }
        .accessibilityLabel(label)
        .accessibilityValue("\(Int(value * 100)) percent")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: value = min(value + 0.05, 1)
            case .decrement: value = max(value - 0.05, 0)
            @unknown default: break
            }
        }
    }
}

// MARK: – Vertical Slider Track (custom, no rotation hacks)

private struct VerticalSliderTrack: View {
    @Binding var value: Double

    private let trackH:   CGFloat = 88
    private let thumbD:   CGFloat = 18
    private let trackW:   CGFloat = 3

    var body: some View {
        ZStack {
            // Track background
            RoundedRectangle(cornerRadius: trackW / 2)
                .fill(AppTheme.borderColor)
                .frame(width: trackW, height: trackH)

            // Active fill — grows from bottom
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                RoundedRectangle(cornerRadius: trackW / 2)
                    .fill(AppTheme.actionOrange)
                    .frame(width: trackW, height: max(0, CGFloat(value) * trackH))
            }
            .frame(height: trackH)

            // Thumb
            Circle()
                .fill(AppTheme.primaryText)
                .frame(width: thumbD, height: thumbD)
                .offset(y: -(CGFloat(value) - 0.5) * trackH)
        }
        .frame(width: 44, height: trackH + thumbD)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { val in
                    let half    = thumbD / 2
                    let usable  = trackH
                    let clamped = min(max(val.location.y - half, 0), usable)
                    value = Double(1.0 - clamped / usable)
                }
        )
    }
}

// MARK: – History Button

private struct HistoryButton: View {
    let systemName: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppTheme.secondaryText)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
