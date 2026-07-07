import SwiftUI
import UniformTypeIdentifiers

struct CRMDataView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                CRMGradientHeader(
                    title: "Import / Export",
                    subtitle: "Move contacts from HubSpot, Salesforce, CSV, vCard, and more",
                    icon: "arrow.up.arrow.down.circle.fill",
                    accent: AppTheme.tealGreen
                )

                NavigationLink {
                    CRMImportView()
                } label: {
                    FeatureCard(title: "Import Contacts", subtitle: "HubSpot, Salesforce, Pipedrive, CSV, vCard, JSON", icon: "square.and.arrow.down.fill", accentColor: AppTheme.tealGreen)
                }.buttonStyle(.plain)

                NavigationLink {
                    BusinessCardsHubView()
                } label: {
                    FeatureCard(title: "Business Cards", subtitle: "Digital card + scan contacts into CRM", icon: "person.text.rectangle.fill", accentColor: AppTheme.electricBlueBright)
                }.buttonStyle(.plain)

                NavigationLink {
                    BusinessCardScanView()
                } label: {
                    FeatureCard(title: "Scan Business Card", subtitle: "Camera OCR capture into CRM", icon: "camera.viewfinder", accentColor: AppTheme.tealGreen)
                }.buttonStyle(.plain)

                NavigationLink {
                    CRMExportView()
                } label: {
                    FeatureCard(title: "Export \(appState.crm.leads.count) Contacts", subtitle: "Download CSV backup", icon: "square.and.arrow.up.fill", accentColor: AppTheme.warningOrange)
                }.buttonStyle(.plain)
            }
            .padding()
        }
        .appBackground()
        .navigationTitle("Import / Export")
    }
}

struct CRMImportView: View {
    @Environment(AppState.self) private var appState
    @State private var showImporter = false
    @State private var importResult: CRMImportResult?
    @State private var selectedSource: CRMImportSource = .genericCSV

    private var ownerId: String { appState.auth.currentUser?.id ?? "" }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                CRMGradientHeader(
                    title: "Import CRM Data",
                    subtitle: "Bring your book from any major CRM export",
                    icon: "doc.badge.plus",
                    accent: AppTheme.electricBlueBright
                )

                Picker("Source", selection: $selectedSource) {
                    ForEach(CRMImportSource.allCases) { source in
                        Text(source.rawValue).tag(source)
                    }
                }
                .pickerStyle(.menu)

                Text(selectedSource.hint)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cardStyle()

                PrimaryButton(title: "Choose File", icon: "folder.fill") {
                    showImporter = true
                }

                if let result = importResult {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Imported \(result.imported) contacts")
                            .font(.headline)
                            .foregroundStyle(AppTheme.successGreen)
                        if result.duplicates > 0 {
                            Text("\(result.duplicates) duplicates skipped")
                                .font(.caption)
                                .foregroundStyle(AppTheme.warningOrange)
                        }
                        ForEach(result.errors, id: \.self) { error in
                            Text(error).font(.caption).foregroundStyle(AppTheme.textMuted)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cardStyle()
                }

                SectionHeader(title: "Supported Exports")
                ForEach(CRMImportSource.allCases) { source in
                    HStack(spacing: 12) {
                        Image(systemName: source.icon)
                            .foregroundStyle(AppTheme.tealGreen)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(source.rawValue).font(.subheadline.bold())
                            Text(source.hint).font(.caption2).foregroundStyle(AppTheme.textMuted).lineLimit(2)
                        }
                        Spacer()
                    }
                    .cardStyle()
                }
            }
            .padding()
        }
        .appBackground()
        .navigationTitle("Import")
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: allowedTypes,
            allowsMultipleSelection: false
        ) { result in
            handleImport(result)
        }
    }

    private var allowedTypes: [UTType] {
        switch selectedSource {
        case .json: return [.json, .plainText]
        case .vcard: return [UTType(filenameExtension: "vcf") ?? .plainText, .plainText]
        default: return [.commaSeparatedText, .plainText, .json]
        }
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        guard case .success(let urls) = result, let url = urls.first else { return }
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        guard let data = try? Data(contentsOf: url), let text = String(data: data, encoding: .utf8) else { return }
        importResult = appState.crm.importCSV(text, ownerId: ownerId, source: selectedSource)
    }
}

struct BusinessCardScanView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme
    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var scannedImage: UIImage?
    @State private var scannedContact = ScannedContact()
    @State private var isScanning = false
    @State private var cameraDenied = false
    @State private var showAddLead = false
    @State private var savedMessage = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                CRMGradientHeader(
                    title: "Business Card Scan",
                    subtitle: "Capture contacts with your camera — OCR fills the form",
                    icon: "camera.viewfinder",
                    accent: AppTheme.electricBlueBright
                )

                NavigationLink {
                    DigitalBusinessCardEditorView()
                } label: {
                    FeatureCard(
                        title: "My Digital Card",
                        subtitle: "Create and share your own business card",
                        icon: "creditcard.fill",
                        accentColor: AppTheme.tealGreen
                    )
                }
                .buttonStyle(.plain)

                if let image = scannedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                HStack(spacing: 10) {
                    PrimaryButton(title: isScanning ? "Scanning..." : "Scan with Camera", icon: "camera.fill") {
                        Task { await openCamera() }
                    }
                    .disabled(isScanning)

                    Button {
                        showPhotoPicker = true
                    } label: {
                        Label("Photo", systemImage: "photo")
                            .font(.caption.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(AppTheme.navyCard)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }

                if cameraDenied {
                    Text("Camera access is required. Enable it in Settings → Sales Coach AI → Camera.")
                        .font(.caption)
                        .foregroundStyle(AppTheme.warningOrange)
                        .multilineTextAlignment(.center)
                        .cardStyle()
                }

                if !scannedContact.rawText.isEmpty || !scannedContact.name.isEmpty {
                    VStack(spacing: 12) {
                        SectionHeader(title: "Detected Contact")
                        editableField("Name", $scannedContact.name)
                        editableField("Company", $scannedContact.company)
                        editableField("Title", $scannedContact.title)
                        editableField("Phone", $scannedContact.phone)
                        editableField("Email", $scannedContact.email)
                        editableField("Website", $scannedContact.website)

                        PrimaryButton(title: "Save to CRM", icon: "person.badge.plus") {
                            saveContact()
                        }
                        .disabled(scannedContact.name.isEmpty)

                        if !savedMessage.isEmpty {
                            Text(savedMessage).font(.caption).foregroundStyle(AppTheme.successGreen)
                        }
                    }
                }

                PrimaryButton(title: "Add Contact Manually", icon: "square.and.pencil") {
                    showAddLead = true
                }
            }
            .padding()
        }
        .appBackground()
        .navigationTitle("Business Card Scan")
        .sheet(isPresented: $showCamera) {
            ImagePicker(sourceType: .camera, image: $scannedImage) {
                Task { await processImage() }
            }
        }
        .sheet(isPresented: $showPhotoPicker) {
            ImagePicker(sourceType: .photoLibrary, image: $scannedImage) {
                Task { await processImage() }
            }
        }
        .sheet(isPresented: $showAddLead) { AddLeadView() }
    }

    private func editableField(_ label: String, _ value: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption.bold()).foregroundStyle(AppTheme.textMuted)
            TextField(label, text: value).textFieldStyle(AppTextFieldStyle())
        }
    }

    private func openCamera() async {
        if BusinessCardScannerService.cameraAuthorized() {
            showCamera = true
            return
        }
        let granted = await BusinessCardScannerService.requestCameraAccess()
        if granted {
            showCamera = true
        } else {
            cameraDenied = true
        }
    }

    private func processImage() async {
        guard let image = scannedImage else { return }
        isScanning = true
        defer { isScanning = false }
        let text = await BusinessCardScannerService.recognizeText(in: image)
        scannedContact = BusinessCardScannerService.parseContact(from: text)
    }

    private func saveContact() {
        let lead = Lead(
            ownerId: appState.auth.currentUser?.id ?? "",
            name: scannedContact.name,
            company: scannedContact.company,
            phone: scannedContact.phone,
            email: scannedContact.email,
            notes: [scannedContact.title, scannedContact.website].filter { !$0.isEmpty }.joined(separator: "\n"),
            leadSource: "Business Card Scan"
        )
        if appState.crm.addLead(lead) {
            savedMessage = "\(lead.name) added to CRM."
            scannedContact = ScannedContact()
            scannedImage = nil
            Task { await appState.integrations.notifyZapier(lead: lead, event: "lead.created") }
        } else {
            savedMessage = "Contact may already exist in CRM."
        }
    }
}

private struct ImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    @Binding var image: UIImage?
    var onPicked: () -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let picked = info[.originalImage] as? UIImage {
                parent.image = picked
                parent.onPicked()
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

struct ProposalGeneratorView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedLeadId: String?
    @State private var proposalText = ""
    @State private var isGenerating = false

    private var selectedLead: Lead? {
        guard let id = selectedLeadId else { return appState.crm.leads.first }
        return appState.crm.leads.first { $0.id == id }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Picker("Client", selection: Binding(
                    get: { selectedLeadId ?? appState.crm.leads.first?.id ?? "" },
                    set: { selectedLeadId = $0 }
                )) {
                    ForEach(appState.crm.leads) { lead in
                        Text(lead.name).tag(lead.id)
                    }
                }
                PrimaryButton(title: isGenerating ? "Generating..." : "Generate Proposal", icon: "sparkles") {
                    guard let lead = selectedLead else { return }
                    isGenerating = true
                    Task {
                        proposalText = (try? await OpenAIService.shared.generateFollowUp(type: .email, lead: lead)) ?? "Proposal draft for \(lead.company)"
                        isGenerating = false
                    }
                }
                TextField("Proposal text", text: $proposalText, axis: .vertical)
                    .lineLimit(6...16)
                    .textFieldStyle(AppTextFieldStyle())
                if !proposalText.isEmpty {
                    ShareLink(item: proposalText) { Label("Share Proposal", systemImage: "square.and.arrow.up") }
                }
            }
            .padding()
        }
        .appBackground()
        .navigationTitle("Proposal Generator")
    }
}

struct AutomationWorkflowsView: View {
    @Environment(AppState.self) private var appState

    private let templates = [
        ("New Lead Nurture", "Email day 0 → call day 2 → task day 5"),
        ("Proposal Follow-Up", "Email day 1 → call day 3 → final task day 7"),
        ("Stale Deal Revival", "Email + call if no contact in 14 days"),
        ("Won Deal Onboarding", "Thank-you email + 30-day check-in task")
    ]

    var body: some View {
        List {
            ForEach(appState.crmHub.sequences) { sequence in
                VStack(alignment: .leading, spacing: 6) {
                    Text(sequence.name).font(.headline)
                    Text("\(sequence.steps.count) automated steps").font(.caption).foregroundStyle(AppTheme.textMuted)
                }
            }
            Section("Templates") {
                ForEach(templates, id: \.0) { name, detail in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(name).font(.subheadline.bold())
                        Text(detail).font(.caption).foregroundStyle(AppTheme.textSecondary)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .appBackground()
        .navigationTitle("Automations")
    }
}

struct ManagerReportView: View {
    @Environment(AppState.self) private var appState

    private var report: String {
        let snapshot = appState.crm.snapshot()
        return """
        Weekly Sales Coach Digest
        Pipeline: $\(Int(snapshot.pipelineValue))
        Win rate: \(Int(snapshot.winRate))%
        Follow-ups due: \(appState.crm.overdueFollowUps().count + appState.crm.followUpsToday().count)
        Training avg: \(appState.training.averageScore(for: appState.auth.currentUser?.id ?? ""))
        Focus: Assign objection drills to reps with stale deals.
        """
    }

    var body: some View {
        ScrollView {
            Text(report)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .cardStyle()
                .padding()
        }
        .appBackground()
        .navigationTitle("Manager Report")
    }
}
