import SwiftUI

struct DashboardCustomizeView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private var userId: String { appState.auth.currentUser?.id ?? "" }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Drag to reorder. Toggle widgets on or off. Your layout syncs locally on this device.")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Section("Active Widgets") {
                    ForEach(appState.revenueOS.layout.enabledWidgets) { widget in
                        widgetRow(widget, enabled: true)
                    }
                    .onMove { source, destination in
                        appState.revenueOS.moveWidget(from: source, to: destination)
                        appState.revenueOS.save(for: userId)
                    }
                }

                if !appState.revenueOS.layout.hiddenWidgets.isEmpty {
                    Section("Hidden Widgets") {
                        ForEach(appState.revenueOS.layout.hiddenWidgets) { widget in
                            widgetRow(widget, enabled: false)
                        }
                    }
                }

                Section {
                    Button("Reset to Default Layout", role: .destructive) {
                        appState.revenueOS.resetLayout()
                        appState.revenueOS.save(for: userId)
                    }
                }
            }
            .navigationTitle("Customize Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    EditButton()
                }
            }
        }
    }

    private func widgetRow(_ widget: DashboardWidgetKind, enabled: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: widget.icon)
                .foregroundStyle(AppTheme.electricBlueBright)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(widget.rawValue).font(.subheadline.bold())
                Text(widget.subtitle).font(.caption2).foregroundStyle(AppTheme.textMuted).lineLimit(2)
            }
            Spacer()
            Toggle("", isOn: Binding(
                get: { enabled },
                set: { newValue in
                    appState.revenueOS.setWidget(widget, enabled: newValue)
                    appState.revenueOS.save(for: userId)
                }
            ))
            .labelsHidden()
        }
        .padding(.vertical, 4)
    }
}

struct RevenueOSModuleHubView: View {
    var body: some View {
        PlatformRootView()
    }
}
