import SwiftUI

struct PlaybackControlsRow: View {
    @Bindable var viewModel: ProjectEditorViewModel

    var body: some View {
        // Three-section layout with equal outer widths keeps transport geometrically centered.
        ZStack {
            // ── Center: Transport ─────────────────────────────────────────
            HStack(spacing: 8) {
                TransportButton(systemName: "backward.end.fill",   label: "First Frame")    { viewModel.goToFirstFrame() }
                TransportButton(systemName: "backward.frame.fill", label: "Previous Frame") { viewModel.stepBackward() }

                // Primary Play/Pause
                Button {
                    var tx = Transaction(); tx.animation = nil
                    withTransaction(tx) { viewModel.togglePlayback() }
                } label: {
                    Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(AppTheme.primaryText)
                        .frame(width: 44, height: 44)
                        .background(AppTheme.actionOrange)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(viewModel.isPlaying ? "Pause" : "Play")

                TransportButton(systemName: "forward.frame.fill", label: "Next Frame")  { viewModel.stepForward() }
                TransportButton(systemName: "forward.end.fill",   label: "Last Frame")  { viewModel.goToLastFrame() }
            }

            HStack(spacing: 0) {
                // ── Left: Timecode readout ────────────────────────────────
                VStack(spacing: 1) {
                    Text(viewModel.timeline.currentTimecode)
                        .font(AppTheme.timecodeFont)
                        .foregroundStyle(AppTheme.primaryText)
                        .monospacedDigit()

                    Text("F \(viewModel.timeline.currentFrame)  /  \(viewModel.timeline.config.totalFrames)")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(AppTheme.secondaryText)
                }
                .frame(minWidth: 90, alignment: .leading)
                .padding(.leading, 16)

                Spacer()

                // ── Right: Zoom controls ──────────────────────────────────
                HStack(spacing: 4) {
                    TransportButton(systemName: "minus.magnifyingglass", label: "Zoom Out") {
                        viewModel.timeline.zoomOut()
                    }
                    TransportButton(systemName: "plus.magnifyingglass",  label: "Zoom In") {
                        viewModel.timeline.zoomIn()
                    }
                }
                .frame(minWidth: 90, alignment: .trailing)
                .padding(.trailing, 16)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.surfaceBackground)
        .overlay(alignment: .top)    { AppTheme.divider.frame(height: 1) }
        .overlay(alignment: .bottom) { AppTheme.divider.frame(height: 1) }
    }
}

// MARK: – Transport Button

private struct TransportButton: View {
    let systemName: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button {
            var transaction = Transaction()
            transaction.animation = nil
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                action()
            }
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppTheme.primaryText)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
