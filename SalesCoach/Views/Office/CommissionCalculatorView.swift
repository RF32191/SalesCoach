import SwiftUI

struct CommissionCalculatorView: View {
    @Environment(AppState.self) private var appState
    @State private var dealValue: Double = 10_000
    @State private var discountPercent: Double = 0
    @State private var commissionRatePercent: Double = 10
    @State private var splitPercent: Double = 100
    @State private var spiff: Double = 0
    @State private var quotaTarget: Double = 25_000

    private var userId: String { appState.auth.currentUser?.id ?? "" }

    private var closedRevenue: Double {
        appState.commission.revenueThisMonth(orders: appState.audit.closedOrders, userId: userId)
    }

    private var closedCommission: Double {
        appState.commission.commissionThisMonth(orders: appState.audit.closedOrders, userId: userId)
    }

    private var calc: CommissionService.CommissionCalculation {
        appState.commission.calculate(
            dealValue: dealValue,
            discountPercent: discountPercent,
            commissionRate: commissionRatePercent / 100,
            splitPercent: splitPercent,
            spiff: spiff,
            closedRevenueThisMonth: closedRevenue
        )
    }

    var body: some View {
        VStack(spacing: 16) {
            CRMGradientHeader(
                title: "Commission Calculator",
                subtitle: "Model deal value, discounts, splits, spiffs, and quota impact",
                icon: "function",
                accent: AppTheme.successGreen
            )

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                statCard("Closed Rev (MTD)", closedRevenue, AppTheme.tealGreen)
                statCard("Commission (MTD)", closedCommission, AppTheme.successGreen)
            }

            calculatorInputs
            resultsCard

            PrimaryButton(title: "Save Quota Target", icon: "target") {
                appState.commission.updateMonthlyTarget(quotaTarget, for: userId)
                appState.commission.updateCommissionRate(commissionRatePercent / 100, for: userId)
            }

            PrimaryButton(title: "Save Rate to CRM Defaults", icon: "percent") {
                appState.commission.updateCommissionRate(commissionRatePercent / 100, for: userId)
                appState.crm.defaultCommissionRate = commissionRatePercent / 100
            }
        }
        .onAppear {
            quotaTarget = appState.commission.settings.monthlyRevenueTarget
            commissionRatePercent = appState.commission.settings.defaultCommissionRate * 100
        }
    }

    private var calculatorInputs: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Deal Inputs")
            labeledSlider("Deal value", value: $dealValue, range: 500...250_000, step: 500, format: "$\(Int(dealValue))")
            labeledSlider("Discount", value: $discountPercent, range: 0...40, step: 1, format: "\(Int(discountPercent))%")
            labeledSlider("Commission rate", value: $commissionRatePercent, range: 1...30, step: 0.5, format: String(format: "%.1f%%", commissionRatePercent))
            labeledSlider("Your split", value: $splitPercent, range: 0...100, step: 5, format: "\(Int(splitPercent))%")
            labeledSlider("Spiff / bonus", value: $spiff, range: 0...5_000, step: 50, format: "$\(Int(spiff))")
            labeledSlider("Monthly quota", value: $quotaTarget, range: 5_000...500_000, step: 1_000, format: "$\(Int(quotaTarget))")
        }
        .cardStyle()
    }

    private var resultsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Payout Breakdown")
            resultRow("Net deal value", calc.netDealValue)
            resultRow("Gross commission", calc.grossCommission)
            resultRow("Your share", calc.yourCommission, highlight: AppTheme.successGreen)
            if calc.spiff > 0 {
                resultRow("Spiff", calc.spiff)
            }
            Divider().overlay(AppTheme.textMuted.opacity(0.3))
            resultRow("Total payout", calc.totalPayout, highlight: AppTheme.tealGreen, bold: true)

            SectionHeader(title: "Quota Impact")
            HStack {
                Text("Progress if closed")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textMuted)
                Spacer()
                Text("\(Int(calc.quotaProgressAfterClose * 100))%")
                    .font(.headline.bold())
                    .foregroundStyle(AppTheme.electricBlueBright)
            }
            if let deals = calc.dealsNeededForQuota {
                Text(deals == 0 ? "Quota already hit this month." : "~\(deals) more deal(s) at this size to hit quota.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .cardStyle()
    }

    private func statCard(_ label: String, _ value: Double, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption2).foregroundStyle(AppTheme.textMuted)
            Text("$\(Int(value))").font(.headline.bold()).foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(AppTheme.navyCard.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func labeledSlider(_ label: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double, format: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label).font(.caption).foregroundStyle(AppTheme.textSecondary)
                Spacer()
                Text(format).font(.caption.bold()).foregroundStyle(AppTheme.textPrimary)
            }
            Slider(value: value, in: range, step: step)
                .tint(AppTheme.tealGreen)
        }
    }

    private func resultRow(_ label: String, _ value: Double, highlight: Color = AppTheme.textPrimary, bold: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(bold ? .subheadline.bold() : .caption)
                .foregroundStyle(AppTheme.textSecondary)
            Spacer()
            Text("$\(value, specifier: "%.2f")")
                .font(bold ? .title3.bold() : .subheadline.bold())
                .foregroundStyle(highlight)
        }
    }
}
