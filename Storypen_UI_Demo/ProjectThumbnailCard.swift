import SwiftUI

/// A masonry thumbnail card for a single project.
///
/// Visual rules (Darkroom design system):
/// - No SF Symbol icons cluttering the card.
/// - No gradients.
/// - Checkerboard at low opacity signals "empty / no rendered frame yet."
/// - A subtle procedural waveform drawn with Canvas conveys "animation project"
///   without being decorative noise.
/// - Metadata sits in a flat `#141414` footer strip separated by a 1px border.
struct ProjectThumbnailCard: View {
    let project: Project

    var body: some View {
        GeometryReader { proxy in
            let width  = proxy.size.width
            let height = width / project.aspectRatio

            ZStack(alignment: .bottomLeading) {
                // Base well
                AppTheme.canvasWell

                // Transparency indicator
                CheckerboardView(squareSize: 14)
                    .opacity(0.14)

                // Procedural waveform — purely decorative, not interactive
                ThumbnailWaveformView(seed: stableHash(project.id))
                    .padding(.horizontal, 10)
                    .padding(.bottom, 30)  // clear footer

                // Footer metadata strip
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.title)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AppTheme.primaryText)
                        .lineLimit(1)

                    Text("00:00:00")
                        .font(AppTheme.timecodeFont)
                        .foregroundStyle(AppTheme.secondaryText)
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 7)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.surfaceBackground)
                .overlay(alignment: .top) {
                    AppTheme.divider.frame(height: 1)
                }
            }
            .frame(width: width, height: height)
            .overlay {
                Rectangle().stroke(AppTheme.borderColor, lineWidth: 1)
            }
        }
        .aspectRatio(project.aspectRatio, contentMode: .fit)
    }

    /// Deterministic integer from UUID so the waveform is stable across redraws.
    private func stableHash(_ id: UUID) -> Int {
        abs(id.hashValue)
    }
}

// MARK: – Procedural Waveform

/// Draws a simple multi-layer sine approximation using Canvas — no UIKit, no gradients.
/// Two passes at different frequencies give a subtle "motion" feel without decoration noise.
private struct ThumbnailWaveformView: View {
    let seed: Int

    var body: some View {
        Canvas { context, size in
            // Derive stable pseudo-random parameters from seed
            let freq1  = Double(1 + (seed % 4))          // 1–4 cycles
            let freq2  = Double(3 + (seed % 5))          // 3–7 cycles
            let phase1 = Double(seed % 100) * 0.063      // 0–6.3
            let amp1   = size.height * 0.22
            let amp2   = size.height * 0.10
            let midY   = size.height * 0.5

            // Secondary wave — fainter
            var path2 = Path()
            for px in stride(from: 0, through: size.width, by: 1.5) {
                let t   = px / size.width
                let y   = midY - sin(t * freq2 * .pi * 2 + phase1 * 0.7) * amp2
                if px == 0 { path2.move(to: CGPoint(x: px, y: y)) }
                else        { path2.addLine(to: CGPoint(x: px, y: y)) }
            }
            context.stroke(
                path2,
                with: .color(AppTheme.borderColor),
                lineWidth: 1
            )

            // Primary wave — medium grey
            var path1 = Path()
            for px in stride(from: 0, through: size.width, by: 1.5) {
                let t   = px / size.width
                let y   = midY - sin(t * freq1 * .pi * 2 + phase1) * amp1
                if px == 0 { path1.move(to: CGPoint(x: px, y: y)) }
                else        { path1.addLine(to: CGPoint(x: px, y: y)) }
            }
            context.stroke(
                path1,
                with: .color(AppTheme.secondaryText.opacity(0.35)),
                lineWidth: 1.5
            )
        }
    }
}
