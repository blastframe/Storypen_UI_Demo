import SwiftUI

/// Top-level editor view. Composes all sub-panels using `ProjectEditorViewModel`
/// as the single source of truth for layout and interaction state.
struct ProjectEditorView: View {
    @Bindable var viewModel: ProjectEditorViewModel
    let onHome: () -> Void

    var body: some View {
        GeometryReader { proxy in
            let availableHeight = max(
                1,
                proxy.size.height
                    - viewModel.headerHeight
                    - viewModel.playbackControlsHeight
                    - viewModel.horizontalDraggerHeight
            )
            let clampedCanvasH   = viewModel.clampedCanvasRowHeight(totalHeight: availableHeight)
            let clampedTimelineH = max(viewModel.minTimelineHeight, availableHeight - clampedCanvasH)

            VStack(spacing: 0) {
                ProjectEditorHeaderView(viewModel: viewModel, onHome: onHome)
                    .frame(height: viewModel.headerHeight)

                CanvasWorkspaceRow(viewModel: viewModel)
                    .frame(height: clampedCanvasH)
                    .clipped()

                PlaybackControlsRow(viewModel: viewModel)
                    .frame(height: viewModel.playbackControlsHeight)

                HorizontalDragger { delta in
                    viewModel.resizeRows(deltaY: delta, totalHeight: availableHeight)
                }
                .frame(height: viewModel.horizontalDraggerHeight)

                Group {
                    if viewModel.usesMetalBackedRendering {
                        TimelineView(viewModel: viewModel.timeline)
                    } else {
                        TimelineRenderingDisabledView(viewModel: viewModel.timeline)
                    }
                }
                .frame(height: clampedTimelineH)
                .clipped()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(AppTheme.baseBackground)
            .ignoresSafeArea(edges: .bottom)
            .onChange(of: proxy.size.height) { _, _ in
                viewModel.normalizeRowHeights(totalHeight: availableHeight)
            }
        }
        .background(AppTheme.baseBackground.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }
}

private struct TimelineRenderingDisabledView: View {
    let viewModel: TimelineViewModel

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Text("TIMELINE")
                    .font(AppTheme.structuralHeaderFont)
                    .tracking(1.6)
                    .foregroundStyle(AppTheme.secondaryText)

                Spacer()

                Text("METAL DISABLED")
                    .font(AppTheme.timecodeFont)
                    .foregroundStyle(AppTheme.actionOrange)

                Text("Frame \(viewModel.currentFrame)")
                    .font(AppTheme.timecodeFont)
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .padding(.horizontal, 14)
            .frame(height: 44)
            .background(AppTheme.surfaceBackground)
            .overlay(alignment: .bottom) {
                AppTheme.divider.frame(height: 1)
            }

            VStack(spacing: 8) {
                ForEach(Array(viewModel.visibleLayers.prefix(4)), id: \.id) { layer in
                    HStack(spacing: 10) {
                        Text(layer.name.uppercased())
                            .font(AppTheme.bodyDenseFont)
                            .foregroundStyle(AppTheme.primaryText)
                            .lineLimit(1)

                        Spacer()

                        RoundedRectangle(cornerRadius: 2)
                            .fill(layer.isSelected ? AppTheme.actionOrange : AppTheme.borderColor)
                            .frame(width: 120, height: 8)
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 28)
                    .background(layer.isSelected ? AppTheme.selectedLayerFill : AppTheme.surfaceBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }

                Text("Timeline canvas and ruler are temporarily replaced with static SwiftUI placeholders.")
                    .font(.system(size: 11, weight: .medium, design: .default))
                    .foregroundStyle(AppTheme.secondaryText)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.top, 6)
            }
            .padding(.top, 14)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(AppTheme.baseBackground)
        }
        .background(AppTheme.surfaceBackground)
        .overlay(alignment: .top) {
            AppTheme.divider.frame(height: 1)
        }
    }
}
