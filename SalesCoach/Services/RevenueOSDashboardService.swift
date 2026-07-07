import Foundation
import SwiftUI

@MainActor
@Observable
final class RevenueOSDashboardService {
    private(set) var layout: DashboardLayout = .default
    private let layoutKey = "salescoach_dashboard_layout"

    func load(for userId: String) {
        let key = "\(layoutKey)_\(userId)"
        guard let data = UserDefaults.standard.data(forKey: key),
              let stored = try? JSONDecoder().decode(DashboardLayout.self, from: data) else {
            layout = .default
            return
        }
        layout = stored
    }

    func save(for userId: String) {
        let key = "\(layoutKey)_\(userId)"
        if let data = try? JSONEncoder().encode(layout) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func setWidget(_ kind: DashboardWidgetKind, enabled: Bool) {
        if enabled {
            layout.hiddenWidgets.removeAll { $0 == kind }
            if !layout.enabledWidgets.contains(kind) {
                layout.enabledWidgets.append(kind)
            }
        } else {
            layout.enabledWidgets.removeAll { $0 == kind }
            if !layout.hiddenWidgets.contains(kind) {
                layout.hiddenWidgets.append(kind)
            }
        }
    }

    func moveWidget(from source: IndexSet, to destination: Int) {
        layout.enabledWidgets.move(fromOffsets: source, toOffset: destination)
    }

    func resetLayout() {
        layout = .default
    }

    func metrics(appState: AppState, userId: String) -> RevenueOSMetrics {
        let snapshot = appState.crm.snapshot()
        let calendar = Calendar.current
        let now = Date.now
        let startOfDay = calendar.startOfDay(for: now)
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
        let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: now)) ?? now

        let orders = appState.audit.closedOrders.filter { $0.ownerId == userId }
        let revenueToday = orders.filter { calendar.isDate($0.closedAt, inSameDayAs: now) }.reduce(0) { $0 + $1.finalValue }
        let revenueMonth = appState.audit.revenueThisMonth(for: userId)
        let revenueYear = orders.filter { $0.closedAt >= startOfYear }.reduce(0) { $0 + $1.finalValue }

        let quotaTarget = appState.commission.settings.monthlyRevenueTarget
        let quotaRevenue = appState.commission.revenueThisMonth(orders: orders, userId: userId)
        let quotaProgress = quotaTarget > 0 ? min(1, quotaRevenue / quotaTarget) : 0

        let won = appState.crm.leads.filter { $0.dealStage == .won }
        let lost = appState.crm.leads.filter { $0.dealStage == .lost }
        let closedCount = won.count + lost.count
        let conversionRate = closedCount > 0 ? Double(won.count) / Double(closedCount) * 100 : 0

        let avgCycle: Int = {
            let cycles = orders.compactMap { order -> Int? in
                guard let lead = appState.crm.leads.first(where: { $0.id == order.leadId }) else { return nil }
                return calendar.dateComponents([.day], from: lead.createdAt, to: order.closedAt).day
            }
            guard !cycles.isEmpty else { return 0 }
            return cycles.reduce(0, +) / cycles.count
        }()

        let activeLeads = appState.crm.leads.filter { $0.dealStage.isActivePipeline }
        let healthScores = activeLeads.map(\.dealHealthScore)
        let avgHealth = healthScores.isEmpty ? 0 : healthScores.reduce(0, +) / healthScores.count
        let atRiskHealth = activeLeads.filter { $0.dealHealthScore < 50 }.count

        return RevenueOSMetrics(
            revenueToday: revenueToday,
            revenueMonth: revenueMonth,
            revenueYear: revenueYear,
            pipelineValue: snapshot.pipelineValue,
            weightedForecast: snapshot.weightedPipeline,
            quotaProgress: quotaProgress,
            quotaTarget: quotaTarget,
            quotaRevenue: quotaRevenue,
            winRate: snapshot.winRate,
            conversionRate: conversionRate,
            avgDealSize: snapshot.avgDealSize,
            avgSalesCycleDays: avgCycle,
            newLeadsThisWeek: appState.crm.leads.filter { $0.createdAt >= startOfWeek }.count,
            hotOpportunities: appState.crm.hotLeads().count,
            dealsAtRisk: appState.crm.staleLeads().count + activeLeads.filter { $0.dealHealthScore < 50 }.count,
            missedFollowUps: appState.crm.overdueFollowUps().count,
            followUpsToday: appState.crm.followUpsToday().count,
            tasksDueToday: appState.crm.tasksDueToday().count,
            tasksOverdue: appState.crm.overdueTasks().count,
            meetingsToday: appState.crm.followUpsToday().count + appState.crm.tasksDueToday().count,
            activeDeals: snapshot.activeDeals,
            avgHealthScore: avgHealth,
            atRiskHealthCount: atRiskHealth
        )
    }
}
