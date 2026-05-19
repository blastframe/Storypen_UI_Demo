import SwiftUI

struct ProjectGridView: View {
    let viewModel: ProjectGridViewModel
    /// Namespace shared with `ProjectShellView` for the hero-zoom card transition.
    let heroNamespace: Namespace.ID

    private let columns  = 3
    private let spacing: CGFloat = 14

    var body: some View {
        VStack(spacing: 0) {
            GridHeaderView(onNewProject: viewModel.newProject)

            ScrollViewReader { proxy in
                ScrollView {
                    MasonryLayout(columns: columns, spacing: spacing) {
                        ForEach(viewModel.projects) { project in
                            Button {
                                viewModel.open(project)
                            } label: {
                                ProjectThumbnailCard(project: project)
                                    // Source anchor for the matchedGeometryEffect zoom transition.
                                    .matchedGeometryEffect(id: project.id, in: heroNamespace)
                            }
                            .buttonStyle(.plain)
                            .id(project.id)
                            .onGeometryChange(for: CGRect.self) { geo in
                                geo.frame(in: .named("shell"))
                            } action: { frame in
                                viewModel.cardFrames[project.id] = frame
                            }
                        }
                    }
                    .padding(16)
                }
                // When returning from the editor, scroll the active project to the top.
                .onChange(of: viewModel.selectedProject) { _, newValue in
                    if newValue == nil, let id = viewModel.lastOpenedProjectID {
                        withAnimation(.easeOut(duration: 0.25)) {
                            proxy.scrollTo(id, anchor: UnitPoint(x: 0.5, y: 0.15))
                        }
                    }
                }
            }
        }
        .background(AppTheme.baseBackground.ignoresSafeArea())
    }
}

// MARK: – Header

private struct GridHeaderView: View {
    let onNewProject: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("STORYPEN")
                    .font(AppTheme.structuralHeaderFont)
                    .tracking(1.6)
                    .foregroundStyle(AppTheme.secondaryText)

                Text("Projects")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(AppTheme.primaryText)
            }

            Spacer()

            Button(action: onNewProject) {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppTheme.primaryText)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("New Project")
        }
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .padding(.bottom, 12)
        .background(AppTheme.surfaceBackground)
        .overlay(alignment: .bottom) {
            AppTheme.divider.frame(height: 1)
        }
    }
}
