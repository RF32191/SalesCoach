import SwiftUI

struct OnboardingTourView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var isPresented: Bool
    @State private var step = 0

    private let tips: [(String, String, String)] = [
        ("Welcome to Sales Coach AI", "Your AI Revenue Operating System — CRM, coaching, intelligence, and field tools in one app.", "sparkles"),
        ("Home dashboard", "Customize widgets, see AI recommendations, and jump to your hottest deals.", "house.fill"),
        ("Sell tab — CRM", "Pipeline, tasks, map prospecting, imports, and business card scan.", "cart.fill"),
        ("Coach tab", "Voice roleplay, AI chat, scripts, Rep DNA, and live call co-pilot.", "mic.fill"),
        ("Platform tab", "35+ modules: forecasting, proposals, integrations, office, and more.", "square.grid.3x3.fill"),
        ("Need help anytime?", "Tap ? on any screen or open Tutorial Library from More → Help.", "graduationcap.fill")
    ]

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: tips[step].2)
                .font(.system(size: 44))
                .foregroundStyle(AppTheme.brandGradient)
                .padding(.top, 8)

            VStack(spacing: 8) {
                Text(tips[step].0)
                    .font(.title2.bold())
                    .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                    .multilineTextAlignment(.center)
                Text(tips[step].1)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 8) {
                ForEach(0..<tips.count, id: \.self) { i in
                    Capsule()
                        .fill(i == step ? AppTheme.electricBlueBright : AppTheme.textMuted.opacity(0.25))
                        .frame(width: i == step ? 24 : 8, height: 8)
                        .animation(.easeInOut(duration: 0.2), value: step)
                }
            }

            HStack(spacing: 12) {
                if step > 0 {
                    SecondaryButton(title: "Back", icon: "chevron.left") {
                        step -= 1
                    }
                }
                PrimaryButton(title: step == tips.count - 1 ? "Get Started" : "Next", icon: step == tips.count - 1 ? "checkmark" : "arrow.right") {
                    if step < tips.count - 1 {
                        step += 1
                    } else {
                        isPresented = false
                    }
                }
            }
        }
        .padding(28)
        .background(AppTheme.cardBackground(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(AppTheme.borderColor(for: colorScheme), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.25), radius: 30, y: 16)
        .padding(24)
    }
}
