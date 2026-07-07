import SwiftUI
import UIKit

struct MainTabView: View {
    @Environment(AppState.self) private var appState
    @AppStorage("salescoach_onboarding_complete") private var onboardingComplete = false
    @State private var showOnboardingTour = false
    @State private var siriPresentation: SiriNavigationRequest?

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = UIColor(AppTheme.deepNavy.opacity(0.92))
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            CRMRootTabView()
                .tabItem {
                    Label("Sell", systemImage: "cart.fill")
                }

            NavigationStack {
                CoachHubView()
            }
            .tabItem {
                Label("Coach", systemImage: "sparkles")
            }

            NavigationStack {
                PlatformRootView()
            }
            .tabItem {
                Label("Platform", systemImage: "square.grid.3x3.fill")
            }

            MoreView()
                .tabItem {
                    Label("More", systemImage: "ellipsis.circle.fill")
                }
        }
        .tint(AppTheme.electricBlueBright)
        .sheet(item: Binding(
            get: { appState.nearbyLeadBriefing },
            set: { appState.nearbyLeadBriefing = $0 }
        )) { lead in
            ProximityBriefingView(lead: lead)
        }
        .fullScreenCover(item: $siriPresentation) { request in
            SiriDestinationView(request: request) {
                siriPresentation = nil
            }
            .environment(appState)
        }
        .onAppear {
            appState.loadUserData()
            Task {
                await appState.setupPermissions()
            }
            if !onboardingComplete {
                showOnboardingTour = true
            }
            wireSiriNavigation()
        }
        .overlay {
            if showOnboardingTour {
                Color.black.opacity(0.55).ignoresSafeArea()
                OnboardingTourView(isPresented: $showOnboardingTour)
            }
        }
        .onChange(of: showOnboardingTour) { _, isShowing in
            if !isShowing { onboardingComplete = true }
        }
    }

    private func wireSiriNavigation() {
        SiriNavigationCenter.shared.onNavigate = { request in
            siriPresentation = request
        }
        if let pending = SiriNavigationCenter.shared.consumePending() {
            siriPresentation = pending
        }
    }
}
