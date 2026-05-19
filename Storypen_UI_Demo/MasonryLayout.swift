import SwiftUI

/// A pure SwiftUI `Layout` that places subviews into `columns` columns
/// using a greedy shortest-column-first algorithm (Pinterest / masonry style).
struct MasonryLayout: Layout {
    var columns: Int
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard !subviews.isEmpty, let containerWidth = proposal.width else { return .zero }

        let (columnWidth, columnHeights) = computeHeights(
            for: subviews,
            containerWidth: containerWidth
        )
        _ = columnWidth  // already used inside helper
        let totalHeight = max(0, (columnHeights.max() ?? 0) - spacing)
        return CGSize(width: containerWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard !subviews.isEmpty else { return }

        let safeColumns  = max(1, columns)
        let columnWidth  = (bounds.width - CGFloat(safeColumns - 1) * spacing) / CGFloat(safeColumns)
        var columnTops   = Array(repeating: bounds.minY, count: safeColumns)

        for subview in subviews {
            let size = subview.sizeThatFits(ProposedViewSize(width: columnWidth, height: nil))
            guard let minY = columnTops.min(), let col = columnTops.firstIndex(of: minY) else { continue }

            let x = bounds.minX + CGFloat(col) * (columnWidth + spacing)
            subview.place(
                at: CGPoint(x: x, y: minY),
                proposal: ProposedViewSize(width: columnWidth, height: size.height)
            )
            columnTops[col] += size.height + spacing
        }
    }

    // MARK: – Private

    private func computeHeights(for subviews: Subviews, containerWidth: CGFloat) -> (CGFloat, [CGFloat]) {
        let safeColumns = max(1, columns)
        let columnWidth = (containerWidth - CGFloat(safeColumns - 1) * spacing) / CGFloat(safeColumns)
        var heights     = Array(repeating: CGFloat(0), count: safeColumns)

        for subview in subviews {
            let size = subview.sizeThatFits(ProposedViewSize(width: columnWidth, height: nil))
            guard let minH = heights.min(), let col = heights.firstIndex(of: minH) else { continue }
            heights[col] += size.height + spacing
        }

        return (columnWidth, heights)
    }
}
