import SwiftUI

enum AppTheme {
    // Brand palette — matched to app icon
    static let deepNavy = Color(red: 0.04, green: 0.06, blue: 0.10)
    static let navyBackground = Color(red: 0.06, green: 0.09, blue: 0.14)
    static let navyCard = Color(red: 0.09, green: 0.13, blue: 0.20)
    static let navyElevated = Color(red: 0.12, green: 0.17, blue: 0.26)
    static let electricBlue = Color(red: 0.10, green: 0.55, blue: 1.0)
    static let electricBlueBright = Color(red: 0.25, green: 0.68, blue: 1.0)
    static let electricBlueDark = Color(red: 0.05, green: 0.35, blue: 0.82)
    static let tealGreen = Color(red: 0.18, green: 0.82, blue: 0.62)
    static let successGreen = Color(red: 0.15, green: 0.88, blue: 0.55)
    static let warningOrange = Color(red: 1.0, green: 0.65, blue: 0.20)
    static let dangerRed = Color(red: 1.0, green: 0.35, blue: 0.35)

    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.68)
    static let textMuted = Color.white.opacity(0.42)
    static let border = Color.white.opacity(0.10)
    static let glassHighlight = Color.white.opacity(0.06)

    // Light mode variants
    static let lightBackground = Color(red: 0.94, green: 0.96, blue: 0.99)
    static let lightCard = Color.white
    static let lightElevated = Color(red: 0.97, green: 0.98, blue: 1.0)
    static let lightTextPrimary = Color(red: 0.06, green: 0.09, blue: 0.16)
    static let lightTextSecondary = Color(red: 0.25, green: 0.32, blue: 0.42)
    static let lightBorder = Color.black.opacity(0.08)

    static func background(for scheme: ColorScheme) -> Color {
        scheme == .dark ? deepNavy : lightBackground
    }

    static func cardBackground(for scheme: ColorScheme) -> Color {
        scheme == .dark ? navyCard.opacity(0.72) : lightCard.opacity(0.88)
    }

    static func elevatedBackground(for scheme: ColorScheme) -> Color {
        scheme == .dark ? navyElevated.opacity(0.65) : lightElevated.opacity(0.92)
    }

    static func primaryText(for scheme: ColorScheme) -> Color {
        scheme == .dark ? textPrimary : lightTextPrimary
    }

    static func secondaryText(for scheme: ColorScheme) -> Color {
        scheme == .dark ? textSecondary : lightTextSecondary
    }

    static func borderColor(for scheme: ColorScheme) -> Color {
        scheme == .dark ? border : lightBorder
    }

    static let accentGradient = LinearGradient(
        colors: [electricBlueBright, electricBlueDark],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let heroGradient = LinearGradient(
        colors: [electricBlue.opacity(0.35), tealGreen.opacity(0.22), deepNavy.opacity(0)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let brandGradient = LinearGradient(
        colors: [electricBlueBright, tealGreen],
        startPoint: .leading,
        endPoint: .trailing
    )
}

struct AdaptiveAppBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            AppTheme.background(for: colorScheme)
                .ignoresSafeArea()

            if colorScheme == .dark {
                darkGlowLayer
            } else {
                lightGlowLayer
            }
        }
    }

    private var darkGlowLayer: some View {
        ZStack {
            RadialGradient(
                colors: [AppTheme.electricBlue.opacity(0.22), .clear],
                center: .topLeading,
                startRadius: 20,
                endRadius: 380
            )
            RadialGradient(
                colors: [AppTheme.tealGreen.opacity(0.14), .clear],
                center: .bottomTrailing,
                startRadius: 10,
                endRadius: 420
            )
            RadialGradient(
                colors: [AppTheme.electricBlueDark.opacity(0.10), .clear],
                center: .center,
                startRadius: 40,
                endRadius: 300
            )
        }
        .ignoresSafeArea()
    }

    private var lightGlowLayer: some View {
        ZStack {
            RadialGradient(
                colors: [AppTheme.electricBlue.opacity(0.12), .clear],
                center: .topLeading,
                startRadius: 20,
                endRadius: 360
            )
            RadialGradient(
                colors: [AppTheme.tealGreen.opacity(0.08), .clear],
                center: .bottomTrailing,
                startRadius: 10,
                endRadius: 400
            )
        }
        .ignoresSafeArea()
    }
}

struct AppBackground: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background {
                AdaptiveAppBackground()
            }
    }
}

extension View {
    func appBackground() -> some View {
        modifier(AppBackground())
    }

    func cardStyle() -> some View {
        modifier(GlassCardModifier())
    }

    func heroGlow() -> some View {
        background {
            Circle()
                .fill(AppTheme.electricBlue.opacity(0.18))
                .blur(radius: 60)
                .offset(y: -20)
        }
    }
}

private struct GlassCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 18)
                    .fill(AppTheme.cardBackground(for: colorScheme))
                    .background {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(AppTheme.glassHighlight)
                    }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        LinearGradient(
                            colors: [
                                AppTheme.electricBlue.opacity(colorScheme == .dark ? 0.28 : 0.18),
                                AppTheme.tealGreen.opacity(colorScheme == .dark ? 0.12 : 0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: AppTheme.electricBlue.opacity(colorScheme == .dark ? 0.08 : 0.04), radius: 16, y: 8)
    }
}
