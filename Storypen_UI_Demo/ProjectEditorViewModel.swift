import SwiftUI

@Observable
final class ProjectEditorViewModel {

    let project: Project
    let usesMetalBackedRendering: Bool

    // MARK: – Child ViewModels

    /// Owns all timeline state: layers, segments, playhead, zoom.
    let timeline: TimelineViewModel

    // MARK: – Playback

    var isPlaying: Bool = false

    // MARK: – Layout

    var isPropertiesPanelVisible: Bool = true
    var canvasRowHeight: CGFloat       = 420
    var propertiesPanelWidth: CGFloat  = 280
    var toolbarOffset: CGSize          = CGSize(width: 24, height: 24)
    var adjustmentsToolbarOffset: CGSize = CGSize(width: 92, height: 24)
    private var hasPlacedAdjustmentsToolbar = false

    // MARK: – Tool selection

    var activeToolTitle: String = DemoData.tools.first?.title ?? "Pencil"
    let tools: [Tool]           = DemoData.tools

    // MARK: – Brush properties

    var brushSize:   Double = 0.42
    var opacity:     Double = 0.86
    var smoothing:   Double = 0.35

    // MARK: – Canvas options

    var showHandles: Bool = true
    var snapToGrid:  Bool = false
    var onionSkin:   Bool = true

    // MARK: – Layout constants (read-only)

    let headerHeight:            CGFloat = 52
    let playbackControlsHeight:  CGFloat = 52
    let horizontalDraggerHeight: CGFloat = 10
    let minCanvasRowHeight:      CGFloat = 220
    let minTimelineHeight:       CGFloat = 160
    let minPropertiesPanelWidth: CGFloat = 220
    let maxPropertiesPanelWidth: CGFloat = 460
    private let adjustmentsToolbarWidth:  CGFloat = 72
    private let adjustmentsToolbarHeight: CGFloat = 320

    // MARK: – Init

    init(project: Project, usesMetalBackedRendering: Bool = true) {
        self.project = project
        self.usesMetalBackedRendering = usesMetalBackedRendering
        self.timeline = TimelineViewModel()
    }

    // MARK: – Layout helpers

    func clampedCanvasRowHeight(totalHeight: CGFloat) -> CGFloat {
        let maxH = max(minCanvasRowHeight, totalHeight - minTimelineHeight)
        return min(max(canvasRowHeight, minCanvasRowHeight), maxH)
    }

    func resizeRows(deltaY: CGFloat, totalHeight: CGFloat) {
        let proposed = canvasRowHeight + deltaY
        let maxH     = max(minCanvasRowHeight, totalHeight - minTimelineHeight)
        canvasRowHeight = min(max(proposed, minCanvasRowHeight), maxH)
    }

    func normalizeRowHeights(totalHeight: CGFloat) {
        let maxH = max(minCanvasRowHeight, totalHeight - minTimelineHeight)
        canvasRowHeight = min(max(canvasRowHeight, minCanvasRowHeight), maxH)
    }

    func clampPropertiesPanelWidth(maxAllowed: CGFloat) -> CGFloat {
        min(max(propertiesPanelWidth, minPropertiesPanelWidth), maxAllowed)
    }

    func resizePropertiesPanel(deltaX: CGFloat, maxAllowed: CGFloat) {
        let proposed = propertiesPanelWidth - deltaX
        propertiesPanelWidth = min(max(proposed, minPropertiesPanelWidth), maxAllowed)
    }

    func clampedToolbarOffset(from offset: CGSize, to size: CGSize, panelWidth: CGFloat) -> CGSize {
        let toolbarW: CGFloat = 60
        let toolbarH: CGFloat = 360
        let pad:      CGFloat = 10
        let avail = max(pad, size.width - panelWidth)
        return CGSize(
            width:  min(max(offset.width,  pad), max(pad, avail - toolbarW - pad)),
            height: min(max(offset.height, pad), max(pad, size.height - toolbarH - pad))
        )
    }

    func clampToolbarOffset(to size: CGSize, panelWidth: CGFloat) {
        toolbarOffset = clampedToolbarOffset(from: toolbarOffset, to: size, panelWidth: panelWidth)
    }

    func clampedAdjustmentsToolbarOffset(from offset: CGSize, to size: CGSize, panelWidth: CGFloat) -> CGSize {
        let pad:      CGFloat = 10
        let avail = max(pad, size.width - panelWidth)
        return CGSize(
            width:  min(max(offset.width,  pad), max(pad, avail - adjustmentsToolbarWidth - pad)),
            height: min(max(offset.height, pad), max(pad, size.height - adjustmentsToolbarHeight - pad))
        )
    }

    func clampAdjustmentsToolbarOffset(to size: CGSize, panelWidth: CGFloat) {
        adjustmentsToolbarOffset = clampedAdjustmentsToolbarOffset(
            from: adjustmentsToolbarOffset,
            to: size,
            panelWidth: panelWidth
        )
    }

    func placeAdjustmentsToolbarOnRightIfNeeded(in size: CGSize, panelWidth: CGFloat) {
        guard !hasPlacedAdjustmentsToolbar, size.width > 0 else { return }
        let pad:      CGFloat = 24
        let avail = max(pad, size.width - panelWidth)
        adjustmentsToolbarOffset = CGSize(
            width: max(pad, avail - adjustmentsToolbarWidth - pad),
            height: pad
        )
        hasPlacedAdjustmentsToolbar = true
    }

    // MARK: – Playback (delegates frame stepping to timeline)

    func togglePlayback() { isPlaying.toggle() }

    func stop() {
        isPlaying = false
        timeline.goToFirstFrame()
    }

    func stepForward() {
        isPlaying = false
        timeline.stepForward()
    }

    func stepBackward() {
        isPlaying = false
        timeline.stepBackward()
    }

    func goToFirstFrame() {
        isPlaying = false
        timeline.goToFirstFrame()
    }

    func goToLastFrame() {
        isPlaying = false
        timeline.goToLastFrame()
    }

    // MARK: – History stubs

    func undoAction() { /* TODO: wire to UndoManager */ }
    func redoAction() { /* TODO: wire to UndoManager */ }

    // MARK: – Panel toggle

    func togglePropertiesPanel() {
        withAnimation(.snappy(duration: 0.22, extraBounce: 0.0)) {
            isPropertiesPanelVisible.toggle()
        }
    }
}
