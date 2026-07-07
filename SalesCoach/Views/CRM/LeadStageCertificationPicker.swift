import SwiftUI

struct LeadStageCertificationPicker: View {
    @Environment(AppState.self) private var appState
    @Binding var lead: Lead
    @State private var showCertificationAlert = false
    @State private var certificationMessage = ""

    var body: some View {
        Picker("Stage", selection: Binding(
            get: { lead.dealStage },
            set: { attemptStageChange($0) }
        )) {
            ForEach(DealStage.allCases) { stage in
                Text(stage.rawValue).tag(stage)
            }
        }
        .pickerStyle(.menu)
        .tint(AppTheme.electricBlue)
        .alert("Certification Required", isPresented: $showCertificationAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(certificationMessage)
        }
    }

    private func attemptStageChange(_ newStage: DealStage) {
        guard newStage != lead.dealStage else { return }
        if appState.crm.moveLead(lead.id, to: newStage),
           let updated = appState.crm.leads.first(where: { $0.id == lead.id }) {
            lead = updated
        } else {
            certificationMessage = appState.crm.lastStageChangeBlockMessage ?? "Complete certification before advancing this deal."
            showCertificationAlert = true
        }
    }
}
