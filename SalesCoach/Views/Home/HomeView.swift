import SwiftUI

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            RevenueOSDashboardView()
                .appBackground()
                .navigationTitle("Home")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.large)
                .toolbarBackground(AppTheme.background(for: colorScheme).opacity(0.85), for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        NavigationLink {
                            TutorialLibraryView()
                        } label: {
                            Image(systemName: "graduationcap.fill")
                                .foregroundStyle(AppTheme.tealGreen)
                        }
                        .accessibilityLabel("Tutorial Library")
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        TutorialHelpButton(tutorialID: .home)
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        NavigationLink {
                            SubscriptionView()
                        } label: {
                            CrownButton(tier: appState.subscription.usage.tier)
                        }
                    }
                }
                #endif
        }
    }
}

struct HomeCategoryChip: View {
    let category: SalesCategory

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: category.icon)
                .font(.title3)
                .foregroundStyle(category.accentColor)
            Text(category.rawValue)
                .font(.caption2.bold())
                .foregroundStyle(AppTheme.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(width: 88)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
        .background(AppTheme.navyCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppTheme.border, lineWidth: 1)
        )
    }
}
