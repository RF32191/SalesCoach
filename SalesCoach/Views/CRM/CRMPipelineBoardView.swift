import SwiftUI

struct CRMPipelineBoardView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 12) {
                ForEach(DealStage.pipelineColumns) { stage in
                    PipelineColumn(stage: stage, leads: leads(for: stage))
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    private func leads(for stage: DealStage) -> [Lead] {
        appState.crm.leads.filter { $0.dealStage == stage }
    }
}

struct PipelineColumn: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme
    let stage: DealStage
    let leads: [Lead]
    @State private var certificationAlert = false
    @State private var certificationMessage = ""

    private var columnValue: Double {
        leads.reduce(0) { $0 + $1.dealValue }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Circle().fill(stage.pipelineColor).frame(width: 8, height: 8)
                    Text(stage.pipelineShortLabel)
                        .font(.caption.bold())
                        .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                HStack {
                    Text("\(leads.count)")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                    Spacer()
                    Text("$\(Int(columnValue))")
                        .font(.caption2.bold())
                        .foregroundStyle(AppTheme.successGreen)
                }
            }
            .padding(.horizontal, 4)

            ForEach(leads) { lead in
                NavigationLink {
                    LeadDetailView(lead: lead)
                } label: {
                    PipelineCard(lead: lead, stageColor: stage.pipelineColor)
                }
                .buttonStyle(.plain)
                .contextMenu {
                    ForEach(DealStage.allCases) { targetStage in
                        if targetStage != lead.dealStage {
                            Button("Move to \(targetStage.rawValue)") {
                                if !appState.crm.moveLead(lead.id, to: targetStage) {
                                    certificationMessage = appState.crm.lastStageChangeBlockMessage ?? "Certification required for this stage."
                                    certificationAlert = true
                                }
                            }
                        }
                    }
                    Button("Mark Contacted Today") {
                        appState.crm.logContact(for: lead.id, type: .call, summary: "Quick contact from pipeline board")
                    }
                }
            }

            if leads.isEmpty {
                Text("No deals")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .background(AppTheme.navyCard.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .frame(width: 250)
        .alert("Certification Required", isPresented: $certificationAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(certificationMessage)
        }
    }
}

struct PipelineCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let lead: Lead
    let stageColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(lead.company.isEmpty ? lead.name : lead.company)
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .minimumScaleFactor(0.85)
                Spacer(minLength: 0)
            }

            Text(lead.name)
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            HStack(spacing: 6) {
                Text("$\(Int(lead.dealValue))")
                    .font(.caption.bold())
                    .foregroundStyle(AppTheme.successGreen)
                    .lineLimit(1)
                Spacer(minLength: 0)
                DealHealthRing(score: lead.dealHealthScore, size: 32)
            }

            HStack(spacing: 6) {
                PriorityBadge(priority: lead.priority)
                Spacer(minLength: 0)
                Text(lead.dealHealthLabel)
                    .font(.caption2.bold())
                    .foregroundStyle(lead.dealHealthColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Text("\(lead.probabilityOfClosing)% close")
                .font(.caption2.bold())
                .foregroundStyle(stageColor)
                .lineLimit(1)

            ProgressView(value: Double(lead.probabilityOfClosing), total: 100)
                .tint(stageColor)

            if let followUp = lead.nextFollowUpDate {
                Label(followUp.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textMuted)
            }
        }
        .padding(12)
        .background(AppTheme.cardBackground(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(stageColor.opacity(0.35), lineWidth: 1)
        )
    }
}
