import SwiftUI

struct PropertiesPanelView: View {
    @Bindable var viewModel: ProjectEditorViewModel

    var body: some View {
        VStack(spacing: 0) {
            // ── Panel Header ──────────────────────────────────────────
            HStack {
                SectionHeader("PROPERTIES")
                Spacer()
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .padding(.horizontal, 14)
            .frame(height: 44)
            .overlay(alignment: .bottom) {
                AppTheme.divider.frame(height: 1)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                // ── Selected Segment Inspector ────────────────────────────
                SegmentInspectorSection(timelineVM: viewModel.timeline)

                AppTheme.divider.frame(height: 1)

                // ── Brush Section ─────────────────────────────────────────
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader("BRUSH")
                    InspectorSliderRow(label: "Size",      value: $viewModel.brushSize)
                    InspectorSliderRow(label: "Opacity",   value: $viewModel.opacity)
                    InspectorSliderRow(label: "Smoothing", value: $viewModel.smoothing)
                }

                AppTheme.divider.frame(height: 1)

                // ── Canvas Section ────────────────────────────────────────
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader("CANVAS")
                    Toggle("Show Handles", isOn: $viewModel.showHandles)
                    Toggle("Snap to Grid", isOn: $viewModel.snapToGrid)
                    Toggle("Onion Skin",   isOn: $viewModel.onionSkin)
                }
                .font(AppTheme.bodyDenseFont)
                .foregroundStyle(AppTheme.primaryText)
                .tint(AppTheme.actionOrange)
                }
                .padding(.horizontal, 14)
                .padding(.top, 14)
                .padding(.bottom, 14)
            }
        }
        .background(AppTheme.surfaceBackground)
    }
}

// MARK: – Segment Inspector Section

private struct SegmentInspectorSection: View {
    @Bindable var timelineVM: TimelineViewModel

    /// Find the selected segment across all layers.
    private var selectedSegment: TimelineSegment? {
        guard let id = timelineVM.selectedSegmentID else { return nil }
        for layer in timelineVM.layers {
            if let seg = layer.segments.first(where: { $0.id == id }) {
                return seg
            }
        }
        return nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader("SEGMENT")

            if let segment = selectedSegment {
                switch segment {
                case .shapeTween(let t):  ShapeTweenInspector(tween: t)
                case .clipInstance(let c): ClipInstanceInspector(clip: c, timelineVM: timelineVM)
                }
            } else {
                Text("No segment selected")
                    .font(AppTheme.bodyDenseFont)
                    .foregroundStyle(AppTheme.secondaryText.opacity(0.6))
            }
        }
    }
}

private struct ShapeTweenInspector: View {
    let tween: ShapeTween

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            InspectorLabelValue(label: "Type",   value: "Shape Tween")
            InspectorLabelValue(label: "Start",  value: "F \(tween.startFrame)")
            InspectorLabelValue(label: "End",    value: "F \(tween.endFrame)")
            InspectorLabelValue(label: "Frames", value: "\(tween.endFrame - tween.startFrame)")
            if !tween.label.isEmpty {
                InspectorLabelValue(label: "Label", value: tween.label)
            }
            // Shape tween indicator
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(AppTheme.actionOrange)
                    .frame(width: 12, height: 12)
                Text("Vector morph active")
                    .font(AppTheme.bodyDenseFont)
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
    }
}

private struct ClipInstanceInspector: View {
    let clip:       ClipInstance
    @Bindable var timelineVM: TimelineViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            InspectorLabelValue(label: "Type",          value: "Clip Instance")
            InspectorLabelValue(label: "Clip",          value: clip.clipAsset.name)
            InspectorLabelValue(label: "Start",         value: "F \(clip.startFrame)")
            InspectorLabelValue(label: "End",           value: "F \(clip.endFrame)")
            InspectorLabelValue(label: "Duration",      value: "\(clip.endFrame - clip.startFrame) frames")
            InspectorLabelValue(label: "Clip Frames",   value: "\(clip.clipAsset.internalFrameCount)")

            // Playback mode picker
            VStack(alignment: .leading, spacing: 4) {
                Text("PLAYBACK MODE")
                    .font(AppTheme.structuralHeaderFont)
                    .tracking(1.2)
                    .foregroundStyle(AppTheme.secondaryText)

                // Inline mode buttons — one per mode
                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: 6
                ) {
                    ForEach(ClipPlaybackMode.allCases) { mode in
                        PlaybackModeButton(
                            mode:     mode,
                            isCurrent: clip.playbackMode == mode
                        ) {
                            updatePlaybackMode(mode)
                        }
                    }
                }
            }

            // Clip container indicator
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(AppTheme.clipFill)
                    .overlay(RoundedRectangle(cornerRadius: 2).stroke(AppTheme.borderColor, lineWidth: 1))
                    .frame(width: 12, height: 12)
                Text("Delegated timeline")
                    .font(AppTheme.bodyDenseFont)
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
    }

    private func updatePlaybackMode(_ mode: ClipPlaybackMode) {
        guard let segID = timelineVM.selectedSegmentID else { return }
        for li in timelineVM.layers.indices {
            for si in timelineVM.layers[li].segments.indices {
                if case .clipInstance(var c) = timelineVM.layers[li].segments[si], c.id == segID {
                    c.playbackMode = mode
                    timelineVM.layers[li].segments[si] = .clipInstance(c)
                    return
                }
            }
        }
    }
}

private struct PlaybackModeButton: View {
    let mode:      ClipPlaybackMode
    let isCurrent: Bool
    let action:    () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: mode.systemImage)
                    .font(.system(size: 9, weight: .semibold))
                Text(mode.rawValue)
                    .font(.system(size: 9, weight: .medium))
                    .lineLimit(1)
            }
            .foregroundStyle(isCurrent ? AppTheme.primaryText : AppTheme.secondaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 5)
            .background(isCurrent ? AppTheme.actionOrange : AppTheme.canvasWell)
            .cornerRadius(2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: – Shared Inspector Atoms

private struct InspectorLabelValue: View {
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 0) {
            Text(label)
                .font(AppTheme.bodyDenseFont)
                .foregroundStyle(AppTheme.secondaryText)
                .frame(width: 72, alignment: .leading)
            Text(value)
                .font(AppTheme.bodyDenseFont)
                .foregroundStyle(AppTheme.primaryText)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}

private struct SectionHeader: View {
    let title: String
    init(_ title: String) { self.title = title }

    var body: some View {
        Text(title)
            .font(AppTheme.structuralHeaderFont)
            .tracking(1.6)
            .foregroundStyle(AppTheme.secondaryText)
    }
}

// MARK: – Slider Row

private struct InspectorSliderRow: View {
    let label: String
    @Binding var value: Double

    var body: some View {
        HStack(spacing: 12) {
            Text(label)
                .font(AppTheme.bodyDenseFont)
                .foregroundStyle(AppTheme.secondaryText)
                .frame(width: 72, alignment: .leading)

            Slider(value: $value, in: 0...1)
                .tint(AppTheme.actionOrange)

            Text(String(format: "%.0f%%", value * 100))
                .font(AppTheme.timecodeFont)
                .foregroundStyle(AppTheme.secondaryText)
                .frame(width: 30, alignment: .trailing)
        }
    }
}
