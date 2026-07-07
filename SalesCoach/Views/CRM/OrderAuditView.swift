import SwiftUI

struct OrderAuditView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        List {
            if appState.audit.entries.isEmpty {
                EmptyStateView(
                    icon: "clock.arrow.circlepath",
                    title: "No audit history",
                    message: "Deal updates, stage changes, and closed orders appear here."
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(appState.audit.entries) { entry in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(entry.summary)
                            .font(.subheadline.bold())
                            .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                        HStack(spacing: 6) {
                            Text(entry.timestamp.formatted(date: .abbreviated, time: .shortened))
                            Text("·")
                            Text(entry.source.rawValue)
                            if !entry.entityLabel.isEmpty {
                                Text("·")
                                Text(entry.entityLabel)
                            }
                        }
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textMuted)
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(AppTheme.cardBackground(for: colorScheme))
                }
            }
        }
        .scrollContentBackground(.hidden)
        .appBackground()
        .navigationTitle("Audit History")
        .navigationBarTitleDisplayMode(.inline)
    }
}
