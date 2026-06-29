import SwiftUI

struct ClosingMeterView: View {
    let progress: Int

    private var clampedProgress: Double {
        Double(min(100, max(0, progress))) / 100.0
    }

    private var statusLabel: String {
        switch progress {
        case 0..<25: "Cold"
        case 25..<50: "Warming Up"
        case 50..<75: "Hot"
        case 75..<90: "Close Ready"
        default: "Deal Closing"
        }
    }

    private var statusColor: Color {
        switch progress {
        case 0..<25: AppTheme.textMuted
        case 25..<50: AppTheme.electricBlueBright
        case 50..<75: AppTheme.warningOrange
        default: AppTheme.tealGreen
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Close Meter", systemImage: "chart.line.uptrend.xyaxis")
                    .font(.caption.bold())
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer()
                Text("\(progress)%")
                    .font(.caption.bold())
                    .foregroundStyle(statusColor)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppTheme.navyElevated)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.electricBlueBright, AppTheme.tealGreen],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * clampedProgress)
                }
            }
            .frame(height: 10)

            Text(statusLabel)
                .font(.caption2.bold())
                .foregroundStyle(statusColor)
        }
        .padding(12)
        .background(AppTheme.navyCard.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppTheme.border, lineWidth: 1)
        )
    }
}

struct CoachSuggestionCard: View {
    let suggestion: String
    var onUse: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(AppTheme.warningOrange)
                Text("Coach Suggestion")
                    .font(.caption.bold())
                    .foregroundStyle(AppTheme.textPrimary)
            }
            Text(suggestion)
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            if let onUse {
                Button("Use This Line", action: onUse)
                    .font(.caption.bold())
                    .foregroundStyle(AppTheme.electricBlueBright)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.warningOrange.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppTheme.warningOrange.opacity(0.25), lineWidth: 1)
        )
    }
}
