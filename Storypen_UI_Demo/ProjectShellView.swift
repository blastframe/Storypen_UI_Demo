import SwiftUI

/// Navigation root. Can temporarily bypass the grid to isolate editor interactions.
struct ProjectShellView: View {
    /// Temporary isolation switch for gesture debugging.
    private let launchesEditorDirectly = false

    @State private var viewModel = ProjectGridViewModel()
    @State private var isolatedEditorViewModel = ProjectEditorViewModel(
        project: DemoData.projects[0],
        usesMetalBackedRendering: true
    )
    @Namespace private var cardHero

    var body: some View {
        if launchesEditorDirectly {
            ProjectEditorView(viewModel: isolatedEditorViewModel, onHome: {})
        } else {
            shellBody
        }
    }

    /// Hosts the grid and transitions into the editor.
    /// The editor expands from/collapses toward the tapped card's position in the grid
    /// using a `matchedGeometryEffect` hero animation: the card thumbnail morphs into
    /// a full-screen background, then the editor content fades in on top.
    private var shellBody: some View {
        GeometryReader { geo in
            ZStack {
                ProjectGridView(viewModel: viewModel, heroNamespace: cardHero)
                    .scaleEffect(viewModel.selectedProject == nil ? 1.0 : 0.985)
                    .allowsHitTesting(viewModel.selectedProject == nil)

                // Hero transition: a full-screen background that animates from the
                // card's frame to fill the screen, with the editor content fading in
                // once expanded. editorViewModel is created once in open() so this
                // branch never re-allocates the VM on re-render.
                if let editorVM = viewModel.editorViewModel,
                   let project  = viewModel.selectedProject {
                    ZStack {
                        // Morphs from the tapped card's frame to fill the screen.
                        AppTheme.baseBackground
                            .matchedGeometryEffect(id: project.id, in: cardHero, isSource: false)
                            .ignoresSafeArea()

                        // Editor content fades in after the background has expanded.
                        ProjectEditorView(viewModel: editorVM) {
                            viewModel.closeEditor()
                        }
                        .opacity(viewModel.isEditorExpanded ? 1.0 : 0.0)
                        .animation(
                            .easeIn(duration: 0.18).delay(viewModel.isEditorExpanded ? 0.14 : 0),
                            value: viewModel.isEditorExpanded
                        )
                    }
                    .zIndex(2)
                }
            }
            .coordinateSpace(name: "shell")
            .onAppear {
                viewModel.shellSize = geo.size
            }
            .onChange(of: geo.size) { _, size in
                viewModel.shellSize = size
            }
        }
        .background(AppTheme.baseBackground.ignoresSafeArea())
    }
}
