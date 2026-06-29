import SwiftUI

struct PrimaryButton: View {
    let title: String
    var icon: String? = nil
    var isLoading: Bool = false
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    if let icon {
                        Image(systemName: icon)
                    }
                    Text(title)
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background {
                if isDisabled {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(AppTheme.textMuted)
                } else {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(AppTheme.accentGradient)
                        .shadow(color: AppTheme.electricBlue.opacity(0.35), radius: 12, y: 6)
                }
            }
            .foregroundStyle(.white)
        }
        .disabled(isDisabled || isLoading)
    }
}

struct SecondaryButton: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    var icon: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                }
                Text(title)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(AppTheme.elevatedBackground(for: colorScheme))
            .foregroundStyle(AppTheme.primaryText(for: colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(AppTheme.borderColor(for: colorScheme), lineWidth: 1)
            )
        }
    }
}

struct SocialSignInButton: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(AppTheme.cardBackground(for: colorScheme))
            .foregroundStyle(AppTheme.primaryText(for: colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(AppTheme.borderColor(for: colorScheme), lineWidth: 1)
            )
        }
    }
}
