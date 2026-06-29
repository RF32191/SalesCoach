import SwiftUI

struct LaunchSplashView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var logoScale: CGFloat = 0.82
    @State private var logoOpacity: Double = 0
    @State private var glowPulse = false
    @State private var wordmarkOffset: CGFloat = 24
    @State private var wordmarkOpacity: Double = 0
    @State private var ringRotation: Double = 0

    let onFinished: () -> Void

    var body: some View {
        ZStack {
            AdaptiveAppBackground()

            VStack(spacing: 28) {
                ZStack {
                    Circle()
                        .stroke(
                            AngularGradient(
                                colors: [
                                    AppTheme.electricBlueBright,
                                    AppTheme.tealGreen,
                                    AppTheme.electricBlueDark,
                                    AppTheme.electricBlueBright
                                ],
                                center: .center
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 220, height: 220)
                        .opacity(glowPulse ? 0.85 : 0.35)
                        .scaleEffect(glowPulse ? 1.04 : 0.96)
                        .rotationEffect(.degrees(ringRotation))

                    AppLogo(size: 180, showGlow: true, cornerRadius: 36)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                }

                BrandWordmark()
                    .offset(y: wordmarkOffset)
                    .opacity(wordmarkOpacity)

                ProgressView()
                    .tint(AppTheme.electricBlueBright)
                    .scaleEffect(1.1)
                    .opacity(wordmarkOpacity)
                    .padding(.top, 8)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.75, dampingFraction: 0.72)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }

            withAnimation(.easeOut(duration: 0.6).delay(0.25)) {
                wordmarkOffset = 0
                wordmarkOpacity = 1.0
            }

            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                glowPulse = true
            }

            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                ringRotation = 360
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                withAnimation(.easeInOut(duration: 0.45)) {
                    onFinished()
                }
            }
        }
    }
}

#Preview {
    LaunchSplashView(onFinished: {})
}
