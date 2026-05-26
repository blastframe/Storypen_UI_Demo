import SwiftUI

// MARK: - Timeline View

/// The full timeline panel.
///
/// Layout:
///   ┌──────────────────────┬──────────────────────────────────────────────┐
///   │   corner spacer      │  ruler  (fixed Y, scrolls H via offset)      │
///   ├──────────────────────┼──────────────────────────────────────────────┤
///   │  Layer header rows   │  Track rows  (single ScrollView — H+V sync)  │
///   └──────────────────────┴──────────────────────────────────────────────┘
///
/// Both left column and track rows live inside the SAME outer ScrollView(.vertical)
/// so they move together. The ruler sits above, not in any scroll view; its content
/// is manually offset by the track area's horizontal scroll position (read via a
/// PreferenceKey from inside the nested ScrollView(.horizontal)).
struct TimelineView: View {
    @Bindable var viewModel: TimelineViewModel

    /// Horizontal scroll offset of the track area — drives the ruler offset.
    @State private var trackHOffset: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            TimelineHeaderBar(viewModel: viewModel)

            GeometryReader { _ in
                VStack(spacing: 0) {
                    rulerRow
                    trackBody
                }
            }
        }
        .background(AppTheme.surfaceBackground)
        .overlay(alignment: .top) { AppTheme.divider.frame(height: 1) }
        .onPreferenceChange(TrackHScrollOffsetKey.self) { offset in
            trackHOffset = max(0, offset)
        }
    }

    // MARK: – Ruler row

    private var rulerRow: some View {
        HStack(spacing: 0) {
            // Corner cell — aligns with frozen left column
            AppTheme.surfaceBackground
                .frame(width: viewModel.trackHeaderWidth)

            AppTheme.divider.frame(width: 1)

            // Ruler viewport: clips to visible width, content offset follows track scroll
            ZStack(alignment: .topLeading) {
                TimelineRulerView(viewModel: viewModel)
                    .frame(width: viewModel.totalTrackWidth, height: viewModel.rulerHeight)
                    .offset(x: -trackHOffset)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .clipped()
            .contentShape(Rectangle())
            // Scrub gesture — adjust location for the ruler's horizontal content offset
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { val in
                        viewModel.currentFrame = viewModel.frame(at: val.location.x + trackHOffset)
                    }
            )
        }
        .frame(height: viewModel.rulerHeight)
        .overlay(alignment: .bottom) { AppTheme.divider.frame(height: 1) }
    }

    // MARK: – Track body

    private var trackBody: some View {
        // Single vertical scroll view wraps BOTH the left column and the track rows.
        // This guarantees they stay vertically in sync at all times.
        ScrollView(.vertical) {
            HStack(alignment: .top, spacing: 0) {
                // ── Frozen left column ───────────────────────────────────
                layerHeaderColumn

                AppTheme.divider.frame(width: 1)

                // ── Track rows (horizontal scroll) ───────────────────────
                ScrollView(.horizontal) {
                    VStack(spacing: 0) {
                        ForEach(Array(viewModel.visibleLayers.enumerated()), id: \.element.id) { idx, layer in
                            TrackRow(layer: layer, viewModel: viewModel)
                                .frame(height: viewModel.trackRowHeight)
                                .frame(width: viewModel.totalTrackWidth)
                        }
                        Spacer(minLength: 0)
                    }
                    .frame(width: viewModel.totalTrackWidth)
                    // Report horizontal scroll position upward for the ruler to follow
                    .background(
                        GeometryReader { geo in
                            Color.clear.preference(
                                key: TrackHScrollOffsetKey.self,
                                value: -geo.frame(in: .named("trackHScroll")).origin.x
                            )
                        }
                    )
                }
                .coordinateSpace(name: "trackHScroll")
                .scrollIndicators(.hidden)
                .frame(maxWidth: .infinity)
            }
        }
        .scrollIndicators(.hidden)
    }

    // MARK: – Layer header column

    /// The frozen left column: layer header rows with drag-reorder support.
    /// An orange 2-pt bar between rows shows the current drop target position.
    private var layerHeaderColumn: some View {
        VStack(spacing: 0) {
            let visible = viewModel.visibleLayers
            ForEach(Array(visible.enumerated()), id: \.element.id) { idx, layer in
                TrackHeaderRow(layer: layer, index: idx, viewModel: viewModel)
                    .frame(height: viewModel.trackRowHeight)
                    // Fade the row being dragged so the user sees it "lifted".
                    .opacity(viewModel.draggingLayerID == layer.id ? 0.35 : 1.0)
                    // Orange drop indicator drawn above this row when it is the target.
                    .overlay(alignment: .top) {
                        if viewModel.dropTargetIndex == idx {
                            dropIndicator
                        }
                    }
            }
            // Indicator appended after the last row (drop-at-end target).
            if viewModel.dropTargetIndex == visible.count {
                dropIndicator
            }
            Spacer(minLength: 0)
        }
        .frame(width: viewModel.trackHeaderWidth)
    }

    private var dropIndicator: some View {
        AppTheme.actionOrange
            .frame(height: 2)
            .shadow(color: AppTheme.actionOrange.opacity(0.55), radius: 3, y: 0)
    }
}

// MARK: - Preference key for horizontal scroll offset

private struct TrackHScrollOffsetKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Timeline Header Bar

private struct TimelineHeaderBar: View {
    @Bindable var viewModel: TimelineViewModel

    var body: some View {
        HStack(spacing: 10) {
            Text("TIMELINE")
                .font(AppTheme.structuralHeaderFont)
                .tracking(1.6)
                .foregroundStyle(AppTheme.secondaryText)

            Spacer()

            // Group button — appears when ≥ 2 non-group layers are selected.
            if viewModel.canGroup {
                Button {
                    withAnimation(.snappy(duration: 0.22)) {
                        viewModel.groupSelectedLayers()
                    }
                } label: {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppTheme.actionOrange)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Group selected layers")
                .transition(.opacity.combined(with: .scale(scale: 0.85)))
            }

            Text("\(Int(viewModel.config.frameRate)) fps")
                .font(AppTheme.timecodeFont)
                .foregroundStyle(AppTheme.secondaryText)

            AppTheme.divider.frame(width: 1).frame(height: 14)

            Menu {
                ForEach(LayerType.allCases) { type in
                    Button {
                        viewModel.addLayer(type: type)
                    } label: {
                        Label(type.rawValue, systemImage: type.systemImage)
                    }
                }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.actionOrange)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 44)
        .background(AppTheme.surfaceBackground)
        .overlay(alignment: .bottom) { AppTheme.divider.frame(height: 1) }
        .animation(.easeInOut(duration: 0.15), value: viewModel.canGroup)
    }
}

// MARK: - Track Header Row (left column cell)

private struct TrackHeaderRow: View {
    let layer: TimelineLayer
    /// Index of this row within `viewModel.visibleLayers` — used for drag math.
    let index: Int
    @Bindable var viewModel: TimelineViewModel

    var body: some View {
        HStack(spacing: 6) {

            // ── Leading control ─────────────────────────────────────────
            if layer.isGroup {
                // Collapse / expand chevron
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        viewModel.toggleGroupCollapse(layer.id)
                    }
                } label: {
                    Image(systemName: layer.isCollapsed ? "chevron.right" : "chevron.down")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(layer.isSelected ? AppTheme.actionOrange : AppTheme.secondaryText)
                        .frame(width: 14)
                        .padding(.leading, 4)
                }
                .buttonStyle(.plain)

                Image(systemName: "folder.fill")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(layer.isSelected ? AppTheme.actionOrange : AppTheme.secondaryText)
                    .frame(width: 14)
            } else {
                // Child-layer indent
                if layer.parentGroupID != nil {
                    Spacer().frame(width: 14)
                }

                Image(systemName: layer.type.systemImage)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(
                        layer.isSelected ? AppTheme.actionOrange : AppTheme.secondaryText
                    )
                    .frame(width: 14)
            }

            // ── Name ────────────────────────────────────────────────────
            Text(layer.name)
                .font(AppTheme.bodyDenseFont)
                .foregroundStyle(
                    layer.isSelected ? AppTheme.primaryText : AppTheme.secondaryText
                )
                .lineLimit(1)

            Spacer(minLength: 2)

            // ── Visibility ──────────────────────────────────────────────
            Button {
                viewModel.toggleLayerVisibility(layer.id)
            } label: {
                Image(systemName: layer.isVisible ? "eye.fill" : "eye.slash")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundStyle(
                        layer.isVisible
                            ? (layer.isSelected ? AppTheme.actionOrange : AppTheme.secondaryText)
                            : AppTheme.secondaryText.opacity(0.4)
                    )
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(layer.isVisible ? "Hide layer" : "Show layer")

            // ── Lock ─────────────────────────────────────────────────────
            Button {
                viewModel.toggleLayerLock(layer.id)
            } label: {
                Image(systemName: layer.isLocked ? "lock.fill" : "lock.open")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundStyle(
                        layer.isLocked ? AppTheme.actionOrange : AppTheme.secondaryText.opacity(0.4)
                    )
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(layer.isLocked ? "Unlock layer" : "Lock layer")
        }
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(layer.isSelected ? AppTheme.selectedLayerFill : AppTheme.surfaceBackground)
        .contentShape(Rectangle())
        // Toggle-select: tap adds/removes this layer from the multi-select set.
        .onTapGesture { viewModel.toggleLayerSelection(layer.id) }
        .overlay(alignment: .bottom) { AppTheme.divider.frame(height: 1) }
        // ── Drag-to-reorder gesture ─────────────────────────────────────
        // minimumDistance: 6 ensures taps still fire `onTapGesture` reliably.
        .gesture(
            DragGesture(minimumDistance: 6)
                .onChanged { val in
                    if viewModel.draggingLayerID == nil {
                        viewModel.draggingLayerID = layer.id
                    }
                    let rowH     = viewModel.trackRowHeight
                    let rawIdx   = index + Int((val.translation.height + rowH * 0.5) / rowH)
                    viewModel.dropTargetIndex = max(0, min(viewModel.visibleLayers.count, rawIdx))
                }
                .onEnded { val in
                    let rowH   = viewModel.trackRowHeight
                    let rawIdx = index + Int((val.translation.height + rowH * 0.5) / rowH)
                    let target = max(0, min(viewModel.visibleLayers.count, rawIdx))
                    viewModel.moveVisibleLayer(from: index, toIndex: target)
                    viewModel.draggingLayerID = nil
                    viewModel.dropTargetIndex = nil
                }
        )
    }
}

// MARK: - Timeline Ruler

private struct TimelineRulerView: View {
    let viewModel: TimelineViewModel

    var body: some View {
        Canvas { context, size in
            let ppf      = viewModel.pointsPerFrame
            let total    = viewModel.config.totalFrames
            let interval = viewModel.rulerTickInterval
            let tickH    = size.height

            for frame in 1...total {
                let x       = CGFloat(frame - 1) * ppf
                let isMajor = (frame - 1) % interval == 0
                let tickLen = isMajor ? tickH * 0.55 : tickH * 0.25

                var tick = Path()
                tick.move(to:    CGPoint(x: x, y: tickH))
                tick.addLine(to: CGPoint(x: x, y: tickH - tickLen))
                context.stroke(
                    tick,
                    with: .color(isMajor ? AppTheme.secondaryText.opacity(0.6) : AppTheme.borderColor),
                    lineWidth: 1
                )

                if isMajor && ppf >= 5 {
                    context.draw(
                        Text("\(frame)")
                            .font(.system(size: 8, weight: .medium, design: .monospaced))
                            .foregroundStyle(AppTheme.secondaryText),
                        at: CGPoint(x: x + 2, y: tickH * 0.28),
                        anchor: .leading
                    )
                }
            }

            // Playhead pentagon marker
            let playX = CGFloat(viewModel.currentFrame - 1) * ppf
            let halfW: CGFloat = 6
            let h: CGFloat = 10
            var pentagon = Path()
            pentagon.move(to: CGPoint(x: playX, y: 0))
            pentagon.addLine(to: CGPoint(x: playX + halfW, y: h * 0.38))
            pentagon.addLine(to: CGPoint(x: playX + halfW * 0.68, y: h))
            pentagon.addLine(to: CGPoint(x: playX - halfW * 0.68, y: h))
            pentagon.addLine(to: CGPoint(x: playX - halfW, y: h * 0.38))
            pentagon.closeSubpath()
            context.fill(pentagon, with: .color(AppTheme.actionOrange))
        }
        .background(AppTheme.baseBackground)
        // No DragGesture here — scrubbing is handled by the parent container
        // so it can adjust for the ruler's horizontal content offset.
    }
}

// MARK: - Track Row

private struct TrackRow: View {
    let layer: TimelineLayer
    @Bindable var viewModel: TimelineViewModel

    var body: some View {
        ZStack(alignment: .leading) {
            (layer.isSelected ? AppTheme.selectedLayerFill : AppTheme.surfaceBackground)

            EmptyFrameGrid(viewModel: viewModel)

            ForEach(layer.segments) { segment in
                segmentView(segment)
            }

            PlayheadLine(viewModel: viewModel)
        }
        .clipped()
        .contentShape(Rectangle())
        .onTapGesture { viewModel.selectLayer(layer.id) }
        .overlay(alignment: .bottom) { AppTheme.divider.frame(height: 1) }
    }

    @ViewBuilder
    private func segmentView(_ segment: TimelineSegment) -> some View {
        switch segment {
        case .shapeTween(let tween):
            ShapeTweenBlock(tween: tween, viewModel: viewModel, isSelected: viewModel.selectedSegmentID == tween.id)
                .onTapGesture { viewModel.selectSegment(tween.id) }

        case .clipInstance(let clip):
            ClipInstanceBlock(clip: clip, viewModel: viewModel, isSelected: viewModel.selectedSegmentID == clip.id)
                .onTapGesture { viewModel.selectSegment(clip.id) }
        }
    }
}

// MARK: - Playhead Line

private struct PlayheadLine: View {
    let viewModel: TimelineViewModel

    var body: some View {
        let x = viewModel.xPosition(for: viewModel.currentFrame)
        Rectangle()
            .fill(AppTheme.actionOrange)
            .frame(width: 2)
            .offset(x: x)
    }
}

// MARK: - Empty Frame Grid

private struct EmptyFrameGrid: View {
    let viewModel: TimelineViewModel

    var body: some View {
        Canvas { context, size in
            let ppf      = viewModel.pointsPerFrame
            let total    = viewModel.config.totalFrames
            let interval = viewModel.rulerTickInterval

            for frame in 1...total where (frame - 1) % interval == 0 {
                let x = CGFloat(frame - 1) * ppf
                var line = Path()
                line.move(to:    CGPoint(x: x, y: 0))
                line.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(line, with: .color(AppTheme.borderColor), lineWidth: 1)
            }
        }
    }
}

// MARK: - Shape Tween Block

private struct ShapeTweenBlock: View {
    let tween:      ShapeTween
    let viewModel:  TimelineViewModel
    let isSelected: Bool

    var body: some View {
        let x     = viewModel.xPosition(for: tween.startFrame)
        let width = max(4, CGFloat(tween.endFrame - tween.startFrame) * viewModel.pointsPerFrame - 1)
        let h     = viewModel.trackRowHeight - 8

        ZStack(alignment: .leading) {
            AppTheme.actionOrange.opacity(isSelected ? 1.0 : 0.82)
                .overlay {
                    if isSelected {
                        Rectangle().stroke(AppTheme.primaryText, lineWidth: 1.5)
                    }
                }

            TweenArrowView(width: width, height: h)

            if width > 48 && !tween.label.isEmpty {
                Text(tween.label)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(AppTheme.primaryText.opacity(0.85))
                    .lineLimit(1)
                    .padding(.leading, 12)
            }
        }
        .frame(width: width, height: h)
        .cornerRadius(2)
        .offset(x: x, y: 0)
    }
}

private struct TweenArrowView: View {
    let width:  CGFloat
    let height: CGFloat

    var body: some View {
        Canvas { context, size in
            let midY:      CGFloat = size.height * 0.5
            let dotR:      CGFloat = 3
            let arrowW:    CGFloat = min(size.width - 20, size.width * 0.6)
            let arrowX0:   CGFloat = 8
            let arrowX1:   CGFloat = arrowX0 + arrowW
            let arrowSize: CGFloat = 4

            let startDot = Path(ellipseIn: CGRect(x: arrowX0 - dotR, y: midY - dotR, width: dotR * 2, height: dotR * 2))
            context.fill(startDot, with: .color(.white))

            var shaft = Path()
            shaft.move(to:    CGPoint(x: arrowX0 + dotR,      y: midY))
            shaft.addLine(to: CGPoint(x: arrowX1 - arrowSize, y: midY))
            context.stroke(shaft, with: .color(.white.opacity(0.8)), lineWidth: 1)

            var head = Path()
            head.move(to:    CGPoint(x: arrowX1,              y: midY))
            head.addLine(to: CGPoint(x: arrowX1 - arrowSize,  y: midY - arrowSize * 0.6))
            head.addLine(to: CGPoint(x: arrowX1 - arrowSize,  y: midY + arrowSize * 0.6))
            head.closeSubpath()
            context.fill(head, with: .color(.white))

            let endDot = Path(ellipseIn: CGRect(x: arrowX1 - dotR, y: midY - dotR, width: dotR * 2, height: dotR * 2))
            context.fill(endDot, with: .color(.white))
        }
        .frame(width: width, height: height)
    }
}

// MARK: - Clip Instance Block

private struct ClipInstanceBlock: View {
    let clip:       ClipInstance
    let viewModel:  TimelineViewModel
    let isSelected: Bool

    var body: some View {
        let x     = viewModel.xPosition(for: clip.startFrame)
        let width = max(4, CGFloat(clip.endFrame - clip.startFrame) * viewModel.pointsPerFrame - 1)
        let h     = viewModel.trackRowHeight - 8

        ZStack(alignment: .leading) {
            if isSelected {
                AppTheme.clipFill
                    .overlay { Rectangle().stroke(AppTheme.actionOrange, lineWidth: 1.5) }
            } else {
                AppTheme.clipFill
            }
            clipMiniMap(width: width, height: h)

            HStack(spacing: 5) {
                Circle()
                    .fill(AppTheme.primaryText)
                    .frame(width: 5, height: 5)
                    .padding(.leading, 5)

                if width > 44 {
                    Text(clip.clipAsset.name)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(AppTheme.primaryText.opacity(0.7))
                        .lineLimit(1)
                }

                Spacer(minLength: 2)

                if width > 28 {
                    Image(systemName: clip.playbackMode.systemImage)
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(AppTheme.secondaryText)
                        .padding(.trailing, 5)
                }
            }
        }
        .frame(width: width, height: h)
        .cornerRadius(2)
        .offset(x: x, y: 0)
        .overlay(alignment: .leading) { resizeHandle(edge: .leading, height: h) }
        .overlay(alignment: .trailing) { resizeHandle(edge: .trailing, height: h) }
    }

    private enum Edge { case leading, trailing }

    @ViewBuilder
    private func resizeHandle(edge: Edge, height: CGFloat) -> some View {
        let active = isSelected
        let handleW: CGFloat = active ? 8 : 4
        Rectangle()
            .fill(AppTheme.actionOrange.opacity(active ? 0.95 : 0.5))
            .frame(width: handleW, height: height)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let deltaFrames = Int((value.translation.width / viewModel.pointsPerFrame).rounded())
                        if edge == .leading {
                            viewModel.updateClipDrawingRange(clip.id, start: clip.drawingStartFrame + deltaFrames)
                        } else {
                            viewModel.updateClipDrawingRange(clip.id, end: clip.drawingEndFrame + deltaFrames)
                        }
                    }
            )
    }

    private func clipMiniMap(width: CGFloat, height: CGFloat) -> some View {
        Canvas { context, size in
            let authored = max(1, clip.drawingEndFrame - clip.drawingStartFrame + 1)
            let tileCount = max(1, Int(size.width / 8))
            for idx in 0..<tileCount {
                let frameInClip = resolvedFrame(index: idx, authoredLength: authored)
                let isGhost = frameInClip < clip.drawingStartFrame || frameInClip > clip.drawingEndFrame
                let x = CGFloat(idx) * (size.width / CGFloat(tileCount))
                let rect = CGRect(x: x, y: 3, width: (size.width / CGFloat(tileCount)) - 1, height: size.height - 6)
                context.fill(Path(roundedRect: rect, cornerRadius: 1),
                             with: .color(isGhost ? AppTheme.secondaryText.opacity(0.2) : AppTheme.actionOrange.opacity(0.35)))
            }
        }
        .allowsHitTesting(false)
    }

    private func resolvedFrame(index: Int, authoredLength: Int) -> Int {
        let authoredStart = clip.drawingStartFrame
        let authoredEnd = clip.drawingEndFrame
        switch clip.playbackMode {
        case .hold:
            return min(authoredStart + index, authoredEnd)
        case .playOnce:
            return min(authoredStart + index, authoredEnd + 1)
        case .loop:
            return authoredStart + (index % authoredLength)
        case .pingPong:
            let pingLen = max(1, authoredLength * 2 - 2)
            let p = index % pingLen
            let local = p < authoredLength ? p : pingLen - p
            return authoredStart + local
        case .random:
            return Int.random(in: authoredStart...authoredEnd)
        }
    }
}
