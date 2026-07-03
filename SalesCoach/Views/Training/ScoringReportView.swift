import SwiftUI

struct ScoringReportView: View {
    let report: TrainingScoreReport
    let session: TrainingSession

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Text("Session Complete")
                        .font(.title2.bold())
                        .foregroundStyle(AppTheme.textPrimary)

                    Text("\(session.scenario.rawValue) · \(session.personality.rawValue)")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)

                    ScoreRing(score: report.overallScore, size: 140, lineWidth: 12)

                    Text(scoreLabel)
                        .font(.headline)
                        .foregroundStyle(scoreColor)
                }
                .padding(.top)

                VStack(spacing: 12) {
                    SectionHeader(title: "Category Breakdown")
                    ForEach(report.categories) { category in
                        CategoryScoreBar(category: category)
                    }
                }
                .cardStyle()

                ReportSection(
                    title: "What You Did Well",
                    icon: "hand.thumbsup.fill",
                    items: report.strengths,
                    iconColor: AppTheme.successGreen
                )

                ReportSection(
                    title: "Areas to Improve",
                    icon: "arrow.up.circle.fill",
                    items: report.improvements,
                    iconColor: AppTheme.warningOrange
                )

                ReportSection(
                    title: "Better Response Examples",
                    icon: "text.quote",
                    items: report.betterResponses
                )

                ReportSection(
                    title: "Script Improvements",
                    icon: "doc.text.fill",
                    items: report.scriptSuggestions
                )

                if !session.transcript.isEmpty {
                    callReplaySection
                }
            }
            .padding()
        }
        .appBackground()
        .navigationTitle("Score Report")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private var callReplaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Call Replay")
            Text("Review the conversation — great moments and coaching opportunities highlighted.")
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)

            ForEach(session.transcript) { entry in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(entry.speaker)
                            .font(.caption.bold())
                            .foregroundStyle(entry.speaker == "You" ? AppTheme.electricBlueBright : AppTheme.tealGreen)
                        Spacer()
                        Text(entry.timestamp.formatted(date: .omitted, time: .shortened))
                            .font(.caption2)
                            .foregroundStyle(AppTheme.textMuted)
                    }
                    Text(entry.text)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textPrimary)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(entry.speaker == "You" ? AppTheme.electricBlueBright.opacity(0.1) : AppTheme.navyElevated.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .cardStyle()
    }

    private var scoreLabel: String {
        switch report.overallScore {
        case 90...100: "Outstanding!"
        case 80..<90: "Great job!"
        case 70..<80: "Good progress"
        case 60..<70: "Keep practicing"
        default: "Room to grow"
        }
    }

    private var scoreColor: Color {
        if report.overallScore >= 80 { return AppTheme.successGreen }
        if report.overallScore >= 60 { return AppTheme.electricBlue }
        return AppTheme.warningOrange
    }
}
