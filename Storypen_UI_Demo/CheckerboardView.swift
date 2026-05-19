import SwiftUI

/// Renders a flat checkerboard pattern — used behind canvas and thumbnail wells
/// to indicate alpha / transparent regions.
struct CheckerboardView: View {
    var squareSize: CGFloat = 14

    var body: some View {
        Canvas { context, size in
            let columns = Int(ceil(size.width  / squareSize))
            let rows    = Int(ceil(size.height / squareSize))

            for row in 0...rows {
                for col in 0...columns {
                    let color = (row + col).isMultiple(of: 2)
                        ? AppTheme.checkerLight
                        : AppTheme.checkerDark

                    let rect = CGRect(
                        x: CGFloat(col) * squareSize,
                        y: CGFloat(row) * squareSize,
                        width:  squareSize,
                        height: squareSize
                    )
                    context.fill(Path(rect), with: .color(color))
                }
            }
        }
    }
}
