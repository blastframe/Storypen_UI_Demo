import SwiftUI

// MARK: - Segment Inspector (replaces the old flat LayerStackView)

/// Shows contextual detail for the currently selected timeline segment.
/// The layer list itself now lives in TimelineView's frozen left column.
struct LayerStackView: View {
    @Bindable var viewModel: ProjectEditorViewModel

    var body: some View {
        // This view is now superseded by TimelineView.
        // Left as an empty container so the file compiles; the panel slot
        // in ProjectEditorView now mounts TimelineView directly.
        EmptyView()
    }
}
