import SwiftUI

struct RootView: View {
    @Environment(AppState.self) private var appState
    @State private var showSplash = true

    var body: some View {
        ZStack {
            Group {
                if appState.auth.isAuthenticated {
                    if appState.auth.currentUser?.hasSelectedSalesCategory == true {
                        MainTabView()
                    } else {
                        SalesTeamSetupView()
                    }
                } else {
                    AuthView()
                }
            }
            .opacity(showSplash ? 0 : 1)

            if showSplash {
                LaunchSplashView {
                    showSplash = false
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.45), value: showSplash)
        .animation(.easeInOut, value: appState.auth.isAuthenticated)
    }
}

#Preview {
    RootView()
        .environment(AppState())
}
