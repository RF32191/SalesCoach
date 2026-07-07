import SwiftUI

struct IntegrationsHubView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                CRMGradientHeader(
                    title: "Integrations",
                    subtitle: "HubSpot, Salesforce, Google Calendar, Zapier, and more",
                    icon: "link.circle.fill",
                    accent: AppTheme.electricBlueBright
                )

                NavigationLink {
                    CRMImportView()
                } label: {
                    FeatureCard(title: "Import CRM Data", subtitle: "CSV exports from HubSpot, Salesforce, Pipedrive, Zoho", icon: "square.and.arrow.down.fill", accentColor: AppTheme.tealGreen)
                }.buttonStyle(.plain)

                SectionHeader(title: "CRM Platforms")
                integrationCard(.hubspot, detail: "Import HubSpot exports and sync profile")
                integrationCard(.salesforce, detail: "Import Salesforce reports and lead exports")

                SectionHeader(title: "Calendar & Automation")
                integrationCard(.googleCalendar, detail: "Connect Google Calendar for follow-up sync")
                appleCalendarCard
                integrationCard(.zapier, detail: "Trigger Zaps when leads are created or updated")

                NavigationLink {
                    SettingsView()
                } label: {
                    FeatureCard(title: "API Settings", subtitle: "Railway AI backend and connection status", icon: "gearshape.fill", accentColor: AppTheme.textSecondary)
                }.buttonStyle(.plain)
            }
            .padding()
        }
        .appBackground()
    }

    @ViewBuilder
    private func integrationCard(_ provider: IntegrationProvider, detail: String) -> some View {
        NavigationLink {
            IntegrationSetupView(provider: provider)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: provider.icon)
                    .font(.title3)
                    .foregroundStyle(appState.integrations.isConnected(provider) ? AppTheme.successGreen : AppTheme.electricBlueBright)
                    .frame(width: 32)
                VStack(alignment: .leading, spacing: 4) {
                    Text(provider.rawValue).font(.subheadline.bold())
                    Text(detail).font(.caption).foregroundStyle(AppTheme.textSecondary).lineLimit(2)
                }
                Spacer()
                Text(appState.integrations.isConnected(provider) ? "Connected" : "Set Up")
                    .font(.caption2.bold())
                    .foregroundStyle(appState.integrations.isConnected(provider) ? AppTheme.successGreen : AppTheme.textMuted)
            }
            .cardStyle()
        }
        .buttonStyle(.plain)
    }

    private var appleCalendarCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Apple Calendar", systemImage: IntegrationProvider.appleCalendar.icon)
                    .font(.subheadline.bold())
                Spacer()
                Toggle("", isOn: Binding(
                    get: { appState.calendar.syncEnabled },
                    set: { appState.calendar.syncEnabled = $0 }
                ))
                .labelsHidden()
            }
            Text(appState.calendar.isAuthorized
                 ? "Follow-ups sync to your default calendar."
                 : "Allow calendar access to enable follow-up sync.")
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .cardStyle()
        .task { await appState.calendar.requestAccess() }
    }
}

struct IntegrationSetupView: View {
    @Environment(AppState.self) private var appState
    let provider: IntegrationProvider

    @State private var hubspotPortal = ""
    @State private var salesforceOrg = ""
    @State private var googleEmail = ""
    @State private var zapierWebhook = ""
    @State private var savedMessage = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                CRMGradientHeader(
                    title: provider.rawValue,
                    subtitle: setupSubtitle,
                    icon: provider.icon,
                    accent: AppTheme.tealGreen
                )

                switch provider {
                case .hubspot:
                    TextField("HubSpot Portal ID (optional)", text: $hubspotPortal).textFieldStyle(AppTextFieldStyle())
                    Text("Export contacts or deals from HubSpot → Import, then choose HubSpot Export.")
                        .font(.caption).foregroundStyle(AppTheme.textSecondary).cardStyle()
                    NavigationLink { CRMImportView() } label: {
                        Label("Import HubSpot CSV", systemImage: "square.and.arrow.down")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(AppTheme.tealGreen.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }.buttonStyle(.plain)
                case .salesforce:
                    TextField("Salesforce Org ID (optional)", text: $salesforceOrg).textFieldStyle(AppTextFieldStyle())
                    Text("Use Reports → Export or Data Export, then import as Salesforce Export.")
                        .font(.caption).foregroundStyle(AppTheme.textSecondary).cardStyle()
                    NavigationLink { CRMImportView() } label: {
                        Label("Import Salesforce CSV", systemImage: "square.and.arrow.down")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(AppTheme.tealGreen.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }.buttonStyle(.plain)
                case .googleCalendar:
                    TextField("Google account email", text: $googleEmail)
                        .textFieldStyle(AppTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    Text("Follow-ups sync via Apple Calendar today. Use Zapier to mirror events to Google Calendar.")
                        .font(.caption).foregroundStyle(AppTheme.textSecondary).cardStyle()
                case .zapier:
                    TextField("Zapier Webhook URL", text: $zapierWebhook)
                        .textFieldStyle(AppTextFieldStyle())
                        .textInputAutocapitalization(.never)
                    Text("New leads and imports POST to this webhook as JSON.")
                        .font(.caption).foregroundStyle(AppTheme.textSecondary).cardStyle()
                case .appleCalendar:
                    EmptyView()
                }

                PrimaryButton(title: appState.integrations.isConnected(provider) ? "Update Connection" : "Connect", icon: "link") {
                    saveConnection()
                }

                if appState.integrations.isConnected(provider) {
                    Button("Disconnect", role: .destructive) {
                        appState.integrations.disconnect(provider)
                        savedMessage = "\(provider.rawValue) disconnected."
                    }
                }

                if !savedMessage.isEmpty {
                    Text(savedMessage).font(.caption).foregroundStyle(AppTheme.successGreen)
                }
            }
            .padding()
        }
        .appBackground()
        .navigationTitle(provider.rawValue)
        .onAppear { loadFields() }
    }

    private var setupSubtitle: String {
        switch provider {
        case .hubspot: "Import and manage HubSpot exports"
        case .salesforce: "Import Salesforce lead and contact data"
        case .googleCalendar: "Calendar sync and meeting visibility"
        case .appleCalendar: "Native iOS calendar sync"
        case .zapier: "Automate workflows across your stack"
        }
    }

    private func loadFields() {
        hubspotPortal = appState.integrations.hubspotPortalId
        salesforceOrg = appState.integrations.salesforceOrgId
        googleEmail = appState.integrations.googleCalendarEmail
        zapierWebhook = appState.integrations.zapierWebhookURL
    }

    private func saveConnection() {
        switch provider {
        case .hubspot:
            appState.integrations.hubspotPortalId = hubspotPortal
            appState.integrations.connect(.hubspot)
        case .salesforce:
            appState.integrations.salesforceOrgId = salesforceOrg
            appState.integrations.connect(.salesforce)
        case .googleCalendar:
            appState.integrations.googleCalendarEmail = googleEmail
            appState.integrations.connect(.googleCalendar)
        case .zapier:
            appState.integrations.zapierWebhookURL = zapierWebhook
            appState.integrations.connect(.zapier)
        case .appleCalendar:
            appState.calendar.syncEnabled = true
        }
        savedMessage = "\(provider.rawValue) connected."
    }
}
