import AuthenticationServices
import SwiftUI

struct AuthView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme
    @State private var accountType: AccountType = .individual
    @State private var companyName = ""

    var body: some View {
        NavigationStack {
            ZStack {
                AdaptiveAppBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        VStack(spacing: 20) {
                            AppLogo(size: 140, cornerRadius: 30)
                                .padding(.top, 24)

                            BrandWordmark()

                            Text("AI-powered sales training\n& lightweight CRM")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                                .multilineTextAlignment(.center)
                                .padding(.top, 4)
                        }

                        VStack(spacing: 16) {
                            Picker("Account Type", selection: $accountType) {
                                ForEach(AccountType.allCases) { type in
                                    Text(type.rawValue).tag(type)
                                }
                            }
                            .pickerStyle(.segmented)

                            if accountType == .team {
                                TextField("Company Name", text: $companyName)
                                    .textFieldStyle(AppTextFieldStyle())
                            }

                            if let error = appState.auth.errorMessage {
                                Text(error)
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.dangerRed)
                                    .multilineTextAlignment(.center)
                            }

                            SignInWithAppleButton(.signIn) { request in
                                request.requestedScopes = [.fullName, .email]
                            } onCompletion: { result in
                                Task {
                                    await appState.auth.signInWithApple(
                                        result,
                                        accountType: accountType,
                                        companyName: accountType == .team ? companyName : nil
                                    )
                                    if appState.auth.isAuthenticated {
                                        appState.loadUserData()
                                    }
                                }
                            }
                            .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                            .frame(height: 54)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .disabled(appState.auth.isLoading)

                            Text("Sign in securely with your Apple ID.\nNo password required.")
                                .font(.caption)
                                .foregroundStyle(AppTheme.textMuted)
                                .multilineTextAlignment(.center)
                        }

                        SubscriptionTierPreview()
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
            }
        }
    }
}

struct SubscriptionTierPreview: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "crown.fill")
                    .foregroundStyle(AppTheme.brandGradient)
                Text("Subscription Plans")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.primaryText(for: colorScheme))
            }

            HStack(spacing: 10) {
                ForEach(SubscriptionTier.allCases) { tier in
                    VStack(spacing: 6) {
                        TierCrownIcon(tier: tier, size: 22)
                        Text(tier.rawValue)
                            .font(.caption2.bold())
                            .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .cardStyle()
    }
}

struct AppTextFieldStyle: TextFieldStyle {
    @Environment(\.colorScheme) private var colorScheme

    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(AppTheme.elevatedBackground(for: colorScheme))
            .foregroundStyle(AppTheme.primaryText(for: colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(AppTheme.borderColor(for: colorScheme), lineWidth: 1)
            )
    }
}
