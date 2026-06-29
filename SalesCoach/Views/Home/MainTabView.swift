import SwiftUI
import UIKit

struct MainTabView: View {
    @Environment(AppState.self) private var appState

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

            ChatView()
                .tabItem {
                    Label("Coach", systemImage: "bubble.left.and.bubble.right.fill")
                }

            TrainingHubView()
                .tabItem {
                    Label("Train", systemImage: "mic.fill")
                }

            if appState.subscription.usage.tier.hasCRM {
                CRMView()
                    .tabItem {
                        Label("CRM", systemImage: "person.crop.rectangle.stack.fill")
                    }
            }

            MoreView()
                .tabItem {
                    Label("More", systemImage: "ellipsis.circle.fill")
                }
        }
        .tint(AppTheme.electricBlueBright)
    }
}
