import Foundation

// MARK: - Layer Type

/// The specific computational capability of a layer.
/// Only `.vector` layers can hold shape keyframes and execute shape tweens.
enum LayerType: String, CaseIterable, Identifiable {
    case vector  = "Vector"
    case raster  = "Raster"
    case video   = "Video"
    case audio   = "Audio"
    case threed  = "3D"
    case light   = "Light"
    case camera  = "Camera"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .vector: return "scribble.variable"
        case .raster: return "photo"
        case .video:  return "film"
        case .audio:  return "waveform"
        case .threed: return "cube"
        case .light:  return "lightbulb.fill"
        case .camera: return "camera.fill"
        }
    }

    /// True if this layer type can host shape keyframes / shape tweens.
    var supportsShapeTween: Bool { self == .vector }
}

// MARK: - Clip Playback Mode

/// Controls how a clip instance plays its internal timeline relative to
/// the main timeline's playhead position.
enum ClipPlaybackMode: String, CaseIterable, Identifiable {
    case loop      = "Loop"
    case pingPong  = "Ping-Pong"
    case playOnce  = "Play Once"
    case hold      = "Hold"
    case random    = "Random"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .loop:     return "repeat"
        case .pingPong: return "arrow.left.arrow.right"
        case .playOnce: return "play.fill"
        case .hold:     return "pause.fill"
        case .random:   return "shuffle"
        }
    }
}

// MARK: - Clip Asset

/// A reusable animated asset stored in the project library.
/// When placed on the timeline it becomes a `ClipInstance`.
struct ClipAsset: Identifiable, Hashable {
    let id: UUID
    var name: String
    var internalFrameCount: Int   // total frames in this clip's own timeline

    init(id: UUID = UUID(), name: String, internalFrameCount: Int) {
        self.id = id
        self.name = name
        self.internalFrameCount = max(1, internalFrameCount)
    }
}

// MARK: - Timeline Segment

/// A contiguous block of frames on a single timeline layer.
/// Segments are non-overlapping and ordered by `startFrame`.
enum TimelineSegment: Identifiable {
    /// An active calculated vector morph between two shape keyframes.
    /// Rendered as an orange block with start-dot → arrow → end-dot.
    case shapeTween(ShapeTween)

    /// A placed clip asset instance.
    /// Rendered as a solid grey block; the main timeline delegates
    /// animation to the clip's internal timeline.
    case clipInstance(ClipInstance)

    var id: UUID {
        switch self {
        case .shapeTween(let s):  return s.id
        case .clipInstance(let c): return c.id
        }
    }

    var startFrame: Int {
        switch self {
        case .shapeTween(let s):  return s.startFrame
        case .clipInstance(let c): return c.startFrame
        }
    }

    var endFrame: Int {
        switch self {
        case .shapeTween(let s):  return s.endFrame
        case .clipInstance(let c): return c.endFrame
        }
    }

    var frameCount: Int { endFrame - startFrame + 1 }
}

// MARK: - Shape Tween

/// A vector morph transition between two explicitly set shape keyframes.
struct ShapeTween: Identifiable, Hashable {
    let id: UUID
    var startFrame: Int
    var endFrame:   Int
    var label:      String

    init(id: UUID = UUID(), startFrame: Int, endFrame: Int, label: String = "") {
        self.id = id
        self.startFrame = startFrame
        self.endFrame   = max(startFrame + 1, endFrame)
        self.label      = label
    }
}

// MARK: - Clip Instance

/// A single placement of a `ClipAsset` on the main timeline.
struct ClipInstance: Identifiable, Hashable {
    let id: UUID
    var clipAsset:    ClipAsset
    var startFrame:   Int
    var endFrame:     Int
    var playbackMode: ClipPlaybackMode
    /// 1-based start frame inside the clip asset that marks where authored
    /// drawings begin.
    var drawingStartFrame: Int
    /// 1-based end frame inside the clip asset that marks where authored
    /// drawings end. Playback mode fills any remaining clip duration.
    var drawingEndFrame: Int

    init(
        id: UUID = UUID(),
        clipAsset: ClipAsset,
        startFrame: Int,
        endFrame:   Int,
        playbackMode: ClipPlaybackMode = .loop
    ) {
        self.id           = id
        self.clipAsset    = clipAsset
        self.startFrame   = startFrame
        self.endFrame     = max(startFrame + 1, endFrame)
        self.playbackMode = playbackMode
        self.drawingStartFrame = 1
        self.drawingEndFrame = clipAsset.internalFrameCount
    }
}

// MARK: - Timeline Layer

/// A single track in the timeline. Owns an ordered, non-overlapping list
/// of `TimelineSegment`s. Replaces the old flat `Layer` struct.
struct TimelineLayer: Identifiable {
    let id: UUID
    var name:       String
    var type:       LayerType
    var opacity:    Int          // 0–100
    var isVisible:  Bool
    var isLocked:   Bool
    var isSelected: Bool
    var segments:   [TimelineSegment]   // sorted by startFrame

    // MARK: – Grouping

    /// When `true` this row acts as a collapsible folder header.
    /// Group rows display a chevron and a folder icon instead of a layer-type icon.
    var isGroup:       Bool
    /// Controls whether a group's children are shown. Ignored for non-group layers.
    var isCollapsed:   Bool
    /// `nil` = top-level layer; otherwise the `id` of the parent group layer.
    var parentGroupID: UUID?

    /// Visual indent level: 1 for direct children of a group, 0 for top-level.
    var indentLevel: Int { parentGroupID != nil ? 1 : 0 }

    init(
        id:           UUID = UUID(),
        name:         String,
        type:         LayerType  = .vector,
        opacity:       Int        = 100,
        isVisible:     Bool       = true,
        isLocked:      Bool       = false,
        isSelected:    Bool       = false,
        segments:      [TimelineSegment] = [],
        isGroup:       Bool       = false,
        isCollapsed:   Bool       = false,
        parentGroupID: UUID?      = nil
    ) {
        self.id           = id
        self.name         = name
        self.type         = type
        self.opacity      = opacity
        self.isVisible    = isVisible
        self.isLocked     = isLocked
        self.isSelected   = isSelected
        self.segments     = segments.sorted { $0.startFrame < $1.startFrame }
        self.isGroup      = isGroup
        self.isCollapsed  = isCollapsed
        self.parentGroupID = parentGroupID
    }
}

// MARK: - Timeline Configuration

/// Project-level playback settings.
struct TimelineConfiguration {
    var frameRate:   Double = 24   // fps
    var totalFrames: Int    = 120  // 5 seconds @ 24fps

    var durationSeconds: Double { Double(totalFrames) / frameRate }
}
