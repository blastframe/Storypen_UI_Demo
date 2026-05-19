import SwiftUI

// MARK: – Horizontal Dragger (resize canvas / timeline)

struct HorizontalDragger: View {
    let onDrag: (CGFloat) -> Void

    @State private var lastTranslation: CGFloat = 0

    var body: some View {
        // Plain rect + centered pill — no border lines
        ZStack {
            AppTheme.surfaceBackground
            Capsule()
                .fill(AppTheme.secondaryText.opacity(0.4))
                .frame(width: 36, height: 5)
        }
        .contentShape(Rectangle())
        // `.highPriorityGesture` prevents the adjacent TimelineView ScrollView from
        // stealing the touch before the drag threshold is reached.
        .highPriorityGesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .global)
                .onChanged { value in
                    let delta = value.translation.height - lastTranslation
                    lastTranslation = value.translation.height
                    onDrag(delta)
                }
                .onEnded { _ in
                    lastTranslation = 0
                }
        )
        .accessibilityLabel("Resize canvas / timeline")
    }
}

// MARK: – Vertical Dragger (resize properties panel)

struct VerticalDragger: View {
    let onDrag: (CGFloat) -> Void

    @State private var lastTranslation: CGFloat = 0

    var body: some View {
        ZStack {
            AppTheme.surfaceBackground
            Capsule()
                .fill(AppTheme.secondaryText.opacity(0.4))
                .frame(width: 4, height: 36)
        }
        .contentShape(Rectangle())
        // `.highPriorityGesture` prevents the adjacent PropertiesPanel ScrollView
        // from stealing the touch before the drag threshold is reached.
        .highPriorityGesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .global)
                .onChanged { value in
                    let delta = value.translation.width - lastTranslation
                    lastTranslation = value.translation.width
                    onDrag(delta)
                }
                .onEnded { _ in
                    lastTranslation = 0
                }
        )
        .accessibilityLabel("Resize properties panel")
    }
}
