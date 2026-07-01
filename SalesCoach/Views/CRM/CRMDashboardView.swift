import SwiftUI

struct CRMDashboardView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme

    private var snapshot: CRMSnapshot { appState.crm.snapshot() }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                kpiGrid
                revenueForecastSection
                acquisitionTrendChart
                revenueTrendChart
                pipelineBreakdown
                acquisitionSources
            }
            .padding()
        }
    }

    private var kpiGrid: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                CRMKPICard(title: "Pipeline", value: formatCurrency(snapshot.pipelineValue), trend: nil, icon: "chart.line.uptrend.xyaxis", color: AppTheme.electricBlueBright)
                CRMKPICard(title: "Weighted", value: formatCurrency(snapshot.weightedPipeline), trend: nil, icon: "scalemass.fill", color: AppTheme.tealGreen)
            }
            HStack(spacing: 12) {
                CRMKPICard(title: "Won Revenue", value: formatCurrency(snapshot.wonRevenue), trend: snapshot.revenueTrend, icon: "dollarsign.circle.fill", color: AppTheme.successGreen)
                CRMKPICard(title: "Win Rate", value: "\(Int(snapshot.winRate))%", trend: nil, icon: "trophy.fill", color: AppTheme.warningOrange)
            }
            HStack(spacing: 12) {
                CRMKPICard(title: "Active Deals", value: "\(snapshot.activeDeals)", trend: nil, icon: "person.2.fill", color: AppTheme.electricBlue)
                CRMKPICard(title: "New This Month", value: "\(snapshot.acquisitionsThisMonth)", trend: snapshot.acquisitionTrend, icon: "person.badge.plus", color: AppTheme.tealGreen)
            }
        }
    }

    private var acquisitionTrendChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Client Acquisitions")
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                Text("New clients added per month")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
            }
            CRMBarChart(
                labels: snapshot.monthlyTrends.map(\.label),
                values: snapshot.monthlyTrends.map { Double($0.acquisitions) },
                color: AppTheme.electricBlueBright
            )
            .frame(height: 160)
            .cardStyle()
        }
    }

    private var revenueTrendChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Revenue Closed")
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                Text("Won deal value per month")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
            }
            CRMBarChart(
                labels: snapshot.monthlyTrends.map(\.label),
                values: snapshot.monthlyTrends.map(\.revenueWon),
                color: AppTheme.successGreen
            )
            .frame(height: 160)
            .cardStyle()
        }
    }

    private var revenueForecastSection: some View {
        let forecast = appState.crm.revenueForecast()
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Revenue Forecast")
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                Spacer()
                NavigationLink {
                    RevenueForecastView()
                } label: {
                    Text("Details")
                        .font(.caption.bold())
                        .foregroundStyle(AppTheme.electricBlueBright)
                }
            }
            HStack(spacing: 12) {
                CRMKPICard(title: "Expected", value: formatCurrency(forecast.expectedThisMonth), trend: nil, icon: "dollarsign.circle.fill", color: AppTheme.successGreen)
                CRMKPICard(title: "Best Case", value: formatCurrency(forecast.bestCase), trend: nil, icon: "chart.bar.fill", color: AppTheme.electricBlueBright)
            }
            CRMKPICard(title: "Closing Soon", value: "\(forecast.dealsClosingSoon) deals", trend: nil, icon: "calendar.badge.clock", color: AppTheme.warningOrange)
        }
    }

    private var pipelineBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pipeline by Stage")
                .font(.headline)
                .foregroundStyle(AppTheme.primaryText(for: colorScheme))

            ForEach(snapshot.stageMetrics.filter { $0.stage.isActivePipeline && $0.count > 0 }) { metric in
                HStack(spacing: 12) {
                    Circle().fill(metric.stage.pipelineColor).frame(width: 10, height: 10)
                    Text(metric.stage.rawValue)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                    Spacer()
                    Text("\(metric.count)")
                        .font(.caption.bold())
                        .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                    Text(formatCurrency(metric.value))
                        .font(.subheadline.bold())
                        .foregroundStyle(AppTheme.successGreen)
                }
                .padding(.vertical, 4)
            }
        }
        .cardStyle()
    }

    private var acquisitionSources: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Acquisition Sources")
                .font(.headline)
                .foregroundStyle(AppTheme.primaryText(for: colorScheme))

            if snapshot.topSources.isEmpty {
                Text("Add clients to see where they come from.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
            } else {
                ForEach(snapshot.topSources) { item in
                    HStack {
                        Text(item.source)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                        Spacer()
                        Text("\(item.count) clients")
                            .font(.caption.bold())
                            .foregroundStyle(AppTheme.electricBlueBright)
                    }
                }
            }
        }
        .cardStyle()
    }

    private func formatCurrency(_ value: Double) -> String {
        if value >= 1_000_000 { return String(format: "$%.1fM", value / 1_000_000) }
        if value >= 1_000 { return String(format: "$%.0fK", value / 1_000) }
        return "$\(Int(value))"
    }
}

struct CRMKPICard: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let value: String
    let trend: Double?
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon).foregroundStyle(color)
                Spacer()
                if let trend {
                    TrendBadge(percent: trend)
                }
            }
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(AppTheme.primaryText(for: colorScheme))
            Text(title)
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

struct TrendBadge: View {
    let percent: Double

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: percent >= 0 ? "arrow.up.right" : "arrow.down.right")
            Text("\(abs(Int(percent)))%")
        }
        .font(.caption2.bold())
        .foregroundStyle(percent >= 0 ? AppTheme.successGreen : AppTheme.dangerRed)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background((percent >= 0 ? AppTheme.successGreen : AppTheme.dangerRed).opacity(0.15))
        .clipShape(Capsule())
    }
}

struct CRMBarChart: View {
    let labels: [String]
    let values: [Double]
    let color: Color

    var body: some View {
        let maxValue = max(values.max() ?? 1, 1)

        HStack(alignment: .bottom, spacing: 8) {
            ForEach(Array(labels.enumerated()), id: \.offset) { index, label in
                VStack(spacing: 6) {
                    Spacer(minLength: 0)
                    let value = index < values.count ? values[index] : 0
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.5)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: max(8, CGFloat(value / maxValue) * 100))
                    Text(label)
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textMuted)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, 8)
    }
}
