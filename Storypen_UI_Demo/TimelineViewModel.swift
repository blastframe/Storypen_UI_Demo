import SwiftUI

// MARK: - Timeline View Model

/// Owns all mutable state for the timeline panel:
/// playhead position, zoom level, scroll offset, frame configuration,
/// and the layer/segment selection.
@Observable
final class TimelineViewModel {

    // MARK: – Configuration

    var config: TimelineConfiguration = TimelineConfiguration()

    // MARK: – Layers

    var layers: [TimelineLayer]

    // MARK: – Playhead

    /// 1-based current frame index (1 … config.totalFrames).
    private var storedCurrentFrame: Int = 1
    var currentFrame: Int {
        get { storedCurrentFrame }
        set { storedCurrentFrame = newValue.clamped(to: 1...config.totalFrames) }
    }

    // MARK: – Zoom

    /// Points per frame in the track area. Clamped to [minZoom, maxZoom].
    private var storedPointsPerFrame: CGFloat = 8.0
    var pointsPerFrame: CGFloat {
        get { storedPointsPerFrame }
        set { storedPointsPerFrame = newValue.clamped(to: minPointsPerFrame...maxPointsPerFrame) }
    }
    let minPointsPerFrame: CGFloat = 3.0
    let maxPointsPerFrame: CGFloat = 40.0

    /// Timeline track area width at current zoom.
    var totalTrackWidth: CGFloat { CGFloat(config.totalFrames) * pointsPerFrame }

    // MARK: – Selection

    var selectedSegmentID: UUID?
    var selectedLayerID:   UUID?

    /// The set of layer IDs currently highlighted for multi-select operations
    /// (e.g. grouping). Tapping a header row toggles membership; tapping a
    /// track row performs a single-select (replacing the set).
    var selectedLayerIDs: Set<UUID> = []

    // MARK: – Drag-to-reorder state

    /// ID of the layer currently being dragged (nil when idle).
    var draggingLayerID: UUID? = nil
    /// Index in `visibleLayers` where the dragged row would be inserted.
    var dropTargetIndex: Int?  = nil

    // MARK: – Layout Constants

    let trackHeaderWidth:  CGFloat = 180
    let trackRowHeight:    CGFloat = 34
    let rulerHeight:       CGFloat = 24
    let rulerTickInterval: Int     = 6   // draw a label every N frames

    // MARK: – Init

    init(layers: [TimelineLayer] = DemoData.makeDemoLayers()) {
        self.layers = layers
        // Pre-select first layer
        if let first = layers.first {
            self.selectedLayerID  = first.id
            self.selectedLayerIDs = [first.id]
        }
    }

    // MARK: – Playhead Navigation

    func goToFirstFrame()    { currentFrame = 1 }
    func goToLastFrame()     { currentFrame = config.totalFrames }
    func stepForward()       { currentFrame += 1 }
    func stepBackward()      { currentFrame = max(1, currentFrame - 1) }

    // MARK: – Zoom

    func zoomIn()  { pointsPerFrame *= 1.25 }
    func zoomOut() { pointsPerFrame /= 1.25 }
    func resetZoom() { pointsPerFrame = 8.0 }

    // MARK: – X Position ↔ Frame Conversion

    func xPosition(for frame: Int) -> CGFloat {
        CGFloat(frame - 1) * pointsPerFrame
    }

    func frame(at xPosition: CGFloat) -> Int {
        let f = Int(xPosition / pointsPerFrame) + 1
        return f.clamped(to: 1...config.totalFrames)
    }

    // MARK: – Visible Layers

    /// Returns only the layers that should be displayed, honouring collapsed groups.
    /// Children whose parent group is collapsed are excluded.
    var visibleLayers: [TimelineLayer] {
        var result: [TimelineLayer] = []
        var collapsedGroupIDs: Set<UUID> = []
        for layer in layers {
            if let parentID = layer.parentGroupID, collapsedGroupIDs.contains(parentID) {
                continue
            }
            result.append(layer)
            if layer.isGroup && layer.isCollapsed {
                collapsedGroupIDs.insert(layer.id)
            }
        }
        return result
    }

    // MARK: – Layer Selection

    /// Single-select: replaces the selection set with just this layer.
    /// Used when tapping a track row (right side) where the intent is to
    /// inspect the layer, not build a multi-selection.
    func selectLayer(_ id: UUID) {
        selectedLayerID  = id
        selectedLayerIDs = [id]
        for i in layers.indices {
            layers[i].isSelected = layers[i].id == id
        }
    }

    /// Toggle-select: adds or removes the layer from the multi-select set.
    /// Used when tapping a header row (left column) to build a selection
    /// for grouping or drag-reordering.
    func toggleLayerSelection(_ id: UUID) {
        if selectedLayerIDs.contains(id) {
            selectedLayerIDs.remove(id)
            if selectedLayerID == id {
                selectedLayerID = selectedLayerIDs.first
            }
        } else {
            selectedLayerIDs.insert(id)
            selectedLayerID = id
        }
        for i in layers.indices {
            layers[i].isSelected = selectedLayerIDs.contains(layers[i].id)
        }
    }

    // MARK: – Layer Mutation

    func toggleLayerVisibility(_ id: UUID) {
        guard let i = layers.firstIndex(where: { $0.id == id }) else { return }
        layers[i].isVisible.toggle()
    }

    func toggleLayerLock(_ id: UUID) {
        guard let i = layers.firstIndex(where: { $0.id == id }) else { return }
        layers[i].isLocked.toggle()
    }

    func addLayer(type: LayerType = .vector) {
        let newLayer = TimelineLayer(
            name: "\(type.rawValue) \(layers.count + 1)",
            type: type
        )
        layers.insert(newLayer, at: 0)
        selectLayer(newLayer.id)
    }

    // MARK: – Group Operations

    /// `true` when at least two non-group layers are currently selected,
    /// meaning the "Group" action is available.
    var canGroup: Bool {
        selectedLayerIDs.filter { id in
            layers.first(where: { $0.id == id })?.isGroup == false
        }.count >= 2
    }

    /// Wraps all currently selected non-group layers into a new group folder.
    func groupSelectedLayers() {
        let selectedIDs = selectedLayerIDs.filter { id in
            layers.first(where: { $0.id == id })?.isGroup == false
        }
        guard selectedIDs.count >= 2,
              let insertIdx = layers.firstIndex(where: { selectedIDs.contains($0.id) })
        else { return }

        // Create the group container row.
        let group = TimelineLayer(
            name:    "Group",
            type:    .vector,
            isGroup: true
        )
        let groupID = group.id

        // Extract children (preserve current order) and update their parent.
        let children: [TimelineLayer] = layers
            .filter { selectedIDs.contains($0.id) }
            .map { layer in
                var l = layer
                l.parentGroupID = groupID
                l.isSelected    = false
                return l
            }

        // Remove the individual layers from the flat list.
        layers.removeAll { selectedIDs.contains($0.id) }

        // Insert group + children at the position of the first selected layer.
        let safeInsert = min(insertIdx, layers.count)
        layers.insert(contentsOf: [group] + children, at: safeInsert)

        // Clear selection.
        selectedLayerIDs.removeAll()
        selectedLayerID = nil
        for i in layers.indices { layers[i].isSelected = false }
    }

    /// Expands or collapses a group row.
    func toggleGroupCollapse(_ id: UUID) {
        guard let i = layers.firstIndex(where: { $0.id == id }) else { return }
        layers[i].isCollapsed.toggle()
    }

    // MARK: — Drag-to-Reorder

    /// Moves a layer from one position to another within `visibleLayers`.
    /// The underlying flat `layers` array is updated accordingly.
    func moveVisibleLayer(from sourceIndex: Int, toIndex targetIndex: Int) {
        let visible = visibleLayers
        guard sourceIndex < visible.count,
              targetIndex != sourceIndex,
              targetIndex >= 0, targetIndex <= visible.count
        else { return }

        let sourceID = visible[sourceIndex].id
        guard let sourceActualIdx = layers.firstIndex(where: { $0.id == sourceID }) else { return }

        // Remove the source from the flat array.
        let layer = layers.remove(at: sourceActualIdx)

        // Recompute visible list after removal to find the correct insertion point.
        var visibleAfter: [TimelineLayer] = []
        var collapsedIDs: Set<UUID> = []
        for l in layers {
            if let pID = l.parentGroupID, collapsedIDs.contains(pID) { continue }
            visibleAfter.append(l)
            if l.isGroup && l.isCollapsed { collapsedIDs.insert(l.id) }
        }

        // Adjust the target index for the removal, clamped to the post-removal range.
        let adjustedTarget = (targetIndex > sourceIndex ? targetIndex - 1 : targetIndex)
            .clamped(to: 0...max(0, visibleAfter.count))

        if adjustedTarget < visibleAfter.count {
            let destID = visibleAfter[adjustedTarget].id
            if let destActualIdx = layers.firstIndex(where: { $0.id == destID }) {
                // Always insert before the destination element.
                layers.insert(layer, at: min(destActualIdx, layers.count))
            } else {
                layers.append(layer)
            }
        } else {
            layers.append(layer)
        }
    }

    // MARK: – Segment Selection

    func selectSegment(_ id: UUID) {
        selectedSegmentID = id
    }

    func clearSegmentSelection() {
        selectedSegmentID = nil
    }

    func updateClipDrawingRange(_ id: UUID, start: Int? = nil, end: Int? = nil) {
        mutateClip(id) { clip in
            let maxFrame = clip.clipAsset.internalFrameCount
            let nextStart = (start ?? clip.drawingStartFrame).clamped(to: 1...maxFrame)
            let nextEnd = (end ?? clip.drawingEndFrame).clamped(to: nextStart...maxFrame)
            clip.drawingStartFrame = nextStart
            clip.drawingEndFrame = nextEnd
        }
    }

    func updateClipInstanceRange(_ id: UUID, startFrame: Int? = nil, endFrame: Int? = nil) {
        mutateClip(id) { clip in
            let proposedStart = (startFrame ?? clip.startFrame).clamped(to: 1...config.totalFrames - 1)
            let proposedEnd = (endFrame ?? clip.endFrame).clamped(to: proposedStart + 1...config.totalFrames)
            clip.startFrame = proposedStart
            clip.endFrame = proposedEnd
        }
    }

    private func mutateClip(_ id: UUID, _ mutation: (inout ClipInstance) -> Void) {
        for layerIdx in layers.indices {
            for segIdx in layers[layerIdx].segments.indices {
                guard case .clipInstance(var clip) = layers[layerIdx].segments[segIdx], clip.id == id else { continue }
                mutation(&clip)
                layers[layerIdx].segments[segIdx] = .clipInstance(clip)
                return
            }
        }
    }

    // MARK: – Computed Helpers

    /// Timecode string for a given frame: MM:SS:FF
    func timecode(for frame: Int) -> String {
        let totalSeconds = Double(frame - 1) / config.frameRate
        let minutes      = Int(totalSeconds) / 60
        let seconds      = Int(totalSeconds) % 60
        let frames       = (frame - 1) % Int(config.frameRate)
        return String(format: "%02d:%02d:%02d", minutes, seconds, frames)
    }

    var currentTimecode: String { timecode(for: currentFrame) }
}

// MARK: - Comparable Clamp Helper

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
