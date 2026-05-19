import Foundation

// MARK: - Project

struct Project: Identifiable, Hashable {
    let id: UUID
    let title: String
    let aspectRatio: CGFloat   // width ÷ height of the project canvas

    init(id: UUID = UUID(), title: String, aspectRatio: CGFloat) {
        self.id = id
        self.title = title
        self.aspectRatio = max(aspectRatio, 0.2)
    }
}

// MARK: - Tool

struct Tool: Identifiable {
    let id: UUID
    let title: String
    let systemImage: String

    init(id: UUID = UUID(), title: String, systemImage: String) {
        self.id = id
        self.title = title
        self.systemImage = systemImage
    }
}

// MARK: - Demo Data

enum DemoData {

    // MARK: Projects

    static let projects: [Project] = [
        Project(title: "Coffee Shop Loop",     aspectRatio: 1.35),
        Project(title: "Character Walk",       aspectRatio: 0.72),
        Project(title: "Melbourne Night",      aspectRatio: 1.10),
        Project(title: "Vector Test",          aspectRatio: 1.85),
        Project(title: "Race Sequence",        aspectRatio: 0.82),
        Project(title: "Title Card",           aspectRatio: 1.55),
        Project(title: "Forest Shot",          aspectRatio: 0.66),
        Project(title: "Animatic",             aspectRatio: 1.25),
        Project(title: "Experimental Boil",    aspectRatio: 0.90),
        Project(title: "Storyboard",           aspectRatio: 1.70),
        Project(title: "Face Rig",             aspectRatio: 0.78),
        Project(title: "City Pan",             aspectRatio: 1.42),
    ]

    // MARK: Clip Library

    /// Shared clip assets used across demo layers.
    static let clipLibrary: [ClipAsset] = [
        ClipAsset(name: "Blink",          internalFrameCount:  6),
        ClipAsset(name: "Breathe",        internalFrameCount: 12),
        ClipAsset(name: "Hair Sway",      internalFrameCount:  8),
        ClipAsset(name: "Flame Flicker",  internalFrameCount:  5),
        ClipAsset(name: "Camera Shake",   internalFrameCount:  4),
    ]

    // MARK: Timeline Layers

    /// Builds a rich demo layer stack that exercises shape tweens,
    /// clip instances, all layer types, and all playback modes.
    static func makeDemoLayers() -> [TimelineLayer] {
        let blink    = clipLibrary[0]
        let breathe  = clipLibrary[1]
        let hairSway = clipLibrary[2]
        let flicker  = clipLibrary[3]
        let shake    = clipLibrary[4]

        return [
            // Vector: open→closed mouth shape tween, then a blink loop
            TimelineLayer(
                name: "Mouth",
                type: .vector,
                isSelected: true,
                segments: [
                    .shapeTween(ShapeTween(startFrame:  1, endFrame: 14, label: "Open→Closed")),
                    .clipInstance(ClipInstance(clipAsset: blink,   startFrame: 15, endFrame:  40, playbackMode: .loop)),
                ]
            ),
            // Vector: two successive body tweens
            TimelineLayer(
                name: "Body Line Art",
                type: .vector,
                segments: [
                    .shapeTween(ShapeTween(startFrame:  1, endFrame: 24, label: "Anticipate")),
                    .shapeTween(ShapeTween(startFrame: 25, endFrame: 60, label: "Settle")),
                ]
            ),
            // Raster: full-duration breathe ping-pong
            TimelineLayer(
                name: "Character Color",
                type: .raster,
                segments: [
                    .clipInstance(ClipInstance(clipAsset: breathe,  startFrame: 1, endFrame: 120, playbackMode: .pingPong)),
                ]
            ),
            // Raster: hair boil via random mode
            TimelineLayer(
                name: "Hair",
                type: .raster,
                opacity: 90,
                segments: [
                    .clipInstance(ClipInstance(clipAsset: hairSway, startFrame: 1, endFrame: 120, playbackMode: .random)),
                ]
            ),
            // Vector: shadow arc tween
            TimelineLayer(
                name: "Shadow",
                type: .vector,
                opacity: 60,
                segments: [
                    .shapeTween(ShapeTween(startFrame:  1, endFrame: 48, label: "Shadow Arc")),
                ]
            ),
            // Light: flame flicker, play once then freeze
            TimelineLayer(
                name: "Key Light",
                type: .light,
                segments: [
                    .clipInstance(ClipInstance(clipAsset: flicker,  startFrame: 30, endFrame: 80,  playbackMode: .playOnce)),
                ]
            ),
            // Raster: background held on frame 1
            TimelineLayer(
                name: "Background",
                type: .raster,
                segments: [
                    .clipInstance(ClipInstance(clipAsset: breathe,  startFrame: 1, endFrame: 120, playbackMode: .hold)),
                ]
            ),
            // Camera: shake loop during action beat
            TimelineLayer(
                name: "Camera",
                type: .camera,
                segments: [
                    .clipInstance(ClipInstance(clipAsset: shake,    startFrame: 55, endFrame: 75,  playbackMode: .loop)),
                ]
            ),
        ]
    }

    // MARK: Tools

    static let tools: [Tool] = [
        Tool(title: "Pencil",  systemImage: "pencil"),
        Tool(title: "Eraser",  systemImage: "eraser"),
        Tool(title: "Select",  systemImage: "cursorarrow"),
        Tool(title: "Move",    systemImage: "arrow.up.and.down.and.arrow.left.and.right"),
        Tool(title: "Fill",    systemImage: "paint.bucket.classic"),
        Tool(title: "Shape",   systemImage: "square.on.circle"),
    ]
}
