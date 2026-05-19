import SwiftUI

struct ProjectEditorHeaderView: View {
    @Bindable var viewModel: ProjectEditorViewModel
    let onHome: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Back button
            Button(action: onHome) {
                Image(systemName: "house.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppTheme.primaryText)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back to Projects")

            // Project identity
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.project.title)
                    .font(AppTheme.bodyDenseSemiboldFont)
                    .foregroundStyle(AppTheme.primaryText)
                    .lineLimit(1)
            }

            Spacer()

            // Properties panel toggle
            Button {
                viewModel.togglePropertiesPanel()
            } label: {
                Image(systemName: "sidebar.right")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(
                        viewModel.isPropertiesPanelVisible
                            ? AppTheme.actionOrange
                            : AppTheme.secondaryText
                    )
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                viewModel.isPropertiesPanelVisible ? "Hide Properties" : "Show Properties"
            )
        }
        .padding(.horizontal, 12)
        .background(AppTheme.surfaceBackground)
        .overlay(alignment: .bottom) {
            AppTheme.divider.frame(height: 1)
        }
    }
}
