import SwiftUI
import MetalKit

/// Central design token system for the "Darkroom" visual language.
///
/// Rules:
///   - Zero gradients, zero shadows, zero glow.
///   - A single accent (`actionOrange`) marks the live interaction point.
///   - Depth is achieved through tonal layering only.
///   - 1px `#262626` borders separate all structural zones.
enum AppTheme {

    // MARK: – Accent

    /// The sole interactive accent. Reserved exclusively for: active tools,
    /// Play transport fill, playhead indicator, and active tab underlines.
    static let actionOrange = Color(hex: 0xFF6B00)

    // MARK: – Text & Icon Hierarchy

    static let primaryText   = Color.white
    static let secondaryText = Color(hex: 0x808080)

    // MARK: – Surface Stack (darkest → lightest = floor → raised)

    /// Deepest structural floor — behind all panels.
    static let baseBackground    = Color(hex: 0x0A0A0A)
    /// Standard panel / toolbar surface.
    static let surfaceBackground = Color(hex: 0x141414)
    /// Canvas void — holds the transparency checkerboard.
    static let canvasWell        = Color(hex: 0x1A1A1A)
    /// Timeline clip fill.
    static let clipFill          = Color(hex: 0x2A2A2A)
    /// Selected layer row bump.
    static let selectedLayerFill = Color(hex: 0x202020)

    // MARK: – Borders

    static let borderColor = Color(hex: 0x262626)

    // MARK: – Convenience Aliases

    static let background        = baseBackground
    static let groupedBackground = surfaceBackground
    static let panelBackground   = canvasWell
    static let separator         = borderColor

    // MARK: – Structural Divider

    /// A hairline 1px divider using `borderColor`. Use `.frame(height: 1)` or `.frame(width: 1)`.
    static var divider: some View {
        Rectangle().fill(borderColor)
    }

    // MARK: – Metal Canvas Clear Colors

    static let canvasLight = MTLClearColor(red: 0.91, green: 0.92, blue: 0.94, alpha: 1.0)
    static let canvasDark  = MTLClearColor(red: 0.10, green: 0.10, blue: 0.10, alpha: 1.0)

    // MARK: – Typography

    /// All-caps, generous tracking. Used for structural panel section headers (e.g. LAYERS, BRUSH).
    static let structuralHeaderFont    = Font.system(size: 10, weight: .bold, design: .default)
    static let bodyDenseFont           = Font.system(size: 12, weight: .regular,  design: .default)
    static let bodyDenseSemiboldFont   = Font.system(size: 12, weight: .semibold, design: .default)
    /// Monospaced — mandatory for all timecodes and frame counters.
    static let timecodeFont            = Font.system(size: 11, weight: .medium, design: .monospaced)

    // MARK: – Checkerboard Palette

    static let checkerLight = Color(hex: 0x999999)
    static let checkerDark  = Color(hex: 0x666666)
}
