import SwiftUI

struct AppLogo: View {
    var size: CGFloat = 160
    var showGlow: Bool = true
    var cornerRadius: CGFloat = 28

    var body: some View {
        ZStack {
            if showGlow {
                RoundedRectangle(cornerRadius: cornerRadius + 8)
                    .fill(
                        RadialGradient(
                            colors: [
                                AppTheme.electricBlue.opacity(0.45),
                                AppTheme.tealGreen.opacity(0.20),
                                .clear
                            ],
                            center: .center,
                            startRadius: size * 0.1,
                            endRadius: size * 0.75
                        )
                    )
                    .frame(width: size + 40, height: size + 40)
                    .blur(radius: 18)
            }

            Image("SalesCoachLogo")
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    AppTheme.electricBlueBright.opacity(0.55),
                                    AppTheme.tealGreen.opacity(0.35)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                }
                .shadow(color: AppTheme.electricBlue.opacity(0.35), radius: 24, y: 10)
        }
    }
}

struct BrandWordmark: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 4) {
            Text("SALES")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .tracking(4)
                .foregroundStyle(AppTheme.primaryText(for: colorScheme))

            Text("COACH")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .tracking(8)
                .foregroundStyle(AppTheme.tealGreen)

            HStack(spacing: 10) {
                Capsule()
                    .fill(AppTheme.electricBlue.opacity(0.6))
                    .frame(width: 36, height: 2)
                Image(systemName: "star.fill")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.electricBlueBright)
                Capsule()
                    .fill(AppTheme.tealGreen.opacity(0.6))
                    .frame(width: 36, height: 2)
            }
            .padding(.top, 2)
        }
    }
}

#Preview {
    ZStack {
        AdaptiveAppBackground()
        VStack(spacing: 24) {
            AppLogo(size: 180)
            BrandWordmark()
        }
    }
    .preferredColorScheme(.dark)
}
