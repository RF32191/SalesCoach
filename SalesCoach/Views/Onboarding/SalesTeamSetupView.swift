import SwiftUI

struct SalesTeamSetupView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    var isChangingCategory: Bool = false
    @State private var selectedCategory: SalesCategory = .b2bServices

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    header

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(SalesCategory.allCases) { category in
                            Button {
                                selectedCategory = category
                            } label: {
                                SalesCategorySelectionCard(
                                    category: category,
                                    isSelected: selectedCategory == category
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your workspace will focus on:")
                            .font(.caption.bold())
                            .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                        Text(selectedCategory.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(AppTheme.cardBackground(for: colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    PrimaryButton(title: "Continue with \(selectedCategory.rawValue)", icon: "checkmark.circle.fill") {
                        completeSetup()
                    }
                }
                .padding()
            }
            .appBackground()
            .navigationTitle(isChangingCategory ? "Change Sales Team" : "Your Sales Team")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if isChangingCategory {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                }
            }
            .onAppear {
                if let existing = appState.auth.currentUser?.salesCategory {
                    selectedCategory = existing
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: selectedCategory.icon)
                .font(.system(size: 42))
                .foregroundStyle(selectedCategory.accentColor)
                .frame(width: 84, height: 84)
                .background(selectedCategory.accentColor.opacity(0.15))
                .clipShape(Circle())

            Text("What does your team sell?")
                .font(.title2.bold())
                .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                .multilineTextAlignment(.center)

            Text("We'll tailor your home screen, CRM, and company finder to your sales vertical.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 12)
    }

    private func completeSetup() {
        appState.auth.updateSalesCategory(selectedCategory)
        if isChangingCategory {
            dismiss()
        } else {
            appState.loadUserData()
        }
    }
}

struct SalesCategorySelectionCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let category: SalesCategory
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: category.icon)
                    .foregroundStyle(category.accentColor)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(category.accentColor)
                }
            }

            Text(category.rawValue)
                .font(.caption.bold())
                .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                .multilineTextAlignment(.leading)
                .lineLimit(2)

            Text(category.clientLabel)
                .font(.caption2)
                .foregroundStyle(AppTheme.textMuted)
                .lineLimit(1)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
        .background(AppTheme.cardBackground(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? category.accentColor : AppTheme.borderColor(for: colorScheme), lineWidth: isSelected ? 2 : 1)
        )
    }
}

struct ContactIntelForm: View {
    @Binding var intel: ContactIntel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Personal Details for Proximity Alerts")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)

            Text("We'll remind you of these facts when you're nearby so you can personalize every visit.")
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)

            TextField("What they like (e.g. golf, local sports)", text: $intel.likes)
                .textFieldStyle(AppTextFieldStyle())
            TextField("Interests & hobbies", text: $intel.interests)
                .textFieldStyle(AppTextFieldStyle())
            TextField("Kids' names", text: $intel.kidsNames)
                .textFieldStyle(AppTextFieldStyle())
            TextField("Family notes (spouse, pets, etc.)", text: $intel.familyNotes)
                .textFieldStyle(AppTextFieldStyle())
            TextField("Conversation starters", text: $intel.conversationStarters, axis: .vertical)
                .lineLimit(2...4)
                .textFieldStyle(AppTextFieldStyle())
        }
        .cardStyle()
    }
}
