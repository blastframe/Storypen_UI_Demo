import SwiftUI

@Observable
final class ProjectGridViewModel {
    private(set) var projects: [Project] = DemoData.projects

    // MARK: – Selection / Navigation

    private(set) var selectedProject: Project?
    private(set) var isEditorExpanded: Bool = false
    private(set) var tappedCardAnchor: UnitPoint = .center
    private(set) var lastOpenedProjectID: UUID? = nil

    // The active editor VM — created once in open(), cleared after close animation.
    // Stored here so ProjectShellView never recreates it on re-render (which causes EXC_BAD_ACCESS).
    private(set) var editorViewModel: ProjectEditorViewModel? = nil

    // Card frames in the "shell" coordinate space — updated by onGeometryChange in the grid.
    var cardFrames: [UUID: CGRect] = [:]
    var shellSize: CGSize = .zero

    func open(_ project: Project) {
        lastOpenedProjectID = project.id
        tappedCardAnchor    = anchor(for: project.id)
        editorViewModel     = ProjectEditorViewModel(project: project)
        selectedProject     = project
        isEditorExpanded    = false

        withAnimation(.snappy(duration: 0.34, extraBounce: 0.02)) {
            isEditorExpanded = true
        }
    }

    func closeEditor() {
        withAnimation(.snappy(duration: 0.28, extraBounce: 0.0)) {
            isEditorExpanded = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) { [weak self] in
            self?.selectedProject  = nil
            self?.editorViewModel  = nil
        }
    }

    // MARK: – CRUD stubs

    func newProject() {
        // TODO: present new-project sheet
    }

    // MARK: – Private

    private func anchor(for id: UUID) -> UnitPoint {
        guard shellSize.width > 0, shellSize.height > 0,
              let frame = cardFrames[id] else { return .center }
        let x = min(max(frame.midX / shellSize.width,  0), 1)
        let y = min(max(frame.midY / shellSize.height, 0), 1)
        return UnitPoint(x: x, y: y)
    }
}
