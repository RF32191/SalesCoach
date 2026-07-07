import SwiftUI

struct BusinessCardsHubView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                CRMGradientHeader(
                    title: "Business Cards",
                    subtitle: "Create your digital card or scan someone else's",
                    icon: "person.text.rectangle.fill",
                    accent: AppTheme.electricBlueBright
                )

                NavigationLink {
                    DigitalBusinessCardEditorView()
                } label: {
                    FeatureCard(
                        title: "My Digital Card",
                        subtitle: "Design, preview, and share your card",
                        icon: "creditcard.fill",
                        accentColor: AppTheme.tealGreen
                    )
                }.buttonStyle(.plain)

                NavigationLink {
                    BusinessCardScanView()
                } label: {
                    FeatureCard(
                        title: "Scan a Card",
                        subtitle: "Camera OCR into CRM contacts",
                        icon: "camera.viewfinder",
                        accentColor: AppTheme.electricBlueBright
                    )
                }.buttonStyle(.plain)
            }
            .padding()
        }
        .appBackground()
        .navigationTitle("Business Cards")
    }
}

struct DigitalBusinessCardEditorView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme
    @State private var draft = DigitalBusinessCard(userId: "")
    @State private var savedMessage = ""
    @State private var shareImage: UIImage?

    private var userId: String { appState.auth.currentUser?.id ?? "" }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                DigitalBusinessCardPreview(card: draft, colorScheme: colorScheme)

                if let qr = appState.digitalCard.qrImage(for: draft) {
                    VStack(spacing: 8) {
                        Text("Scan to save contact")
                            .font(.caption.bold())
                            .foregroundStyle(AppTheme.textMuted)
                        Image(uiImage: qr)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 140, height: 140)
                            .padding(12)
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .frame(maxWidth: .infinity)
                    .cardStyle()
                }

                SectionHeader(title: "Card Details")
                cardField("Full Name", text: $draft.fullName)
                cardField("Title", text: $draft.title)
                cardField("Company", text: $draft.company)
                cardField("Phone", text: $draft.phone, keyboard: .phonePad)
                cardField("Email", text: $draft.email, keyboard: .emailAddress, autocapitalization: .never)
                cardField("Website", text: $draft.website, autocapitalization: .never)
                cardField("LinkedIn URL", text: $draft.linkedIn, autocapitalization: .never)
                cardMultilineField("Tagline", text: $draft.tagline)

                SectionHeader(title: "Theme")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(DigitalCardTheme.allCases) { theme in
                            Button {
                                draft.theme = theme
                            } label: {
                                VStack(spacing: 6) {
                                    Circle()
                                        .fill(theme.accent)
                                        .frame(width: 28, height: 28)
                                        .overlay {
                                            if draft.theme == theme {
                                                Image(systemName: "checkmark")
                                                    .font(.caption2.bold())
                                                    .foregroundStyle(.white)
                                            }
                                        }
                                    Text(theme.rawValue)
                                        .font(.caption2)
                                        .foregroundStyle(draft.theme == theme ? theme.accent : AppTheme.textMuted)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                }
                                .frame(width: 72)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                PrimaryButton(title: "Save Card", icon: "square.and.arrow.down.fill") {
                    saveCard()
                }

                if !savedMessage.isEmpty {
                    Text(savedMessage)
                        .font(.caption)
                        .foregroundStyle(AppTheme.successGreen)
                }

                SectionHeader(title: "Share")
                VStack(spacing: 10) {
                    ShareLink(item: draft.shareText) {
                        shareRow("Share as Text", "text.alignleft")
                    }
                    ShareLink(item: draft.vCard) {
                        shareRow("Share vCard (.vcf)", "person.crop.rectangle")
                    }
                    if let image = shareImage, let url = writeShareImage(image) {
                        ShareLink(item: url, preview: SharePreview("My Business Card", image: Image(uiImage: image))) {
                            shareRow("Share Card Image", "photo")
                        }
                    }
                }
            }
            .padding()
        }
        .appBackground()
        .navigationTitle("Digital Business Card")
        .onAppear {
            if let existing = appState.digitalCard.card {
                draft = existing
            } else if let user = appState.auth.currentUser {
                draft = DigitalBusinessCard.fromProfile(user)
            }
            draft.userId = userId
            shareImage = appState.digitalCard.renderShareImage(card: draft, colorScheme: colorScheme)
        }
        .onChange(of: draft) { _, _ in
            shareImage = appState.digitalCard.renderShareImage(card: draft, colorScheme: colorScheme)
        }
    }

    private func cardField(
        _ label: String,
        text: Binding<String>,
        keyboard: UIKeyboardType = .default,
        autocapitalization: TextInputAutocapitalization = .sentences
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption.bold()).foregroundStyle(AppTheme.textMuted)
            TextField(label, text: text)
                .textFieldStyle(AppTextFieldStyle())
                .keyboardType(keyboard)
                .textInputAutocapitalization(autocapitalization)
        }
    }

    private func cardMultilineField(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption.bold()).foregroundStyle(AppTheme.textMuted)
            TextField(label, text: text, axis: .vertical)
                .lineLimit(2...4)
                .textFieldStyle(AppTextFieldStyle())
        }
    }

    private func writeShareImage(_ image: UIImage) -> URL? {
        guard let data = image.pngData() else { return nil }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("salescoach-business-card.png")
        try? data.write(to: url)
        return url
    }

    private func shareRow(_ title: String, _ icon: String) -> some View {
        HStack {
            Label(title, systemImage: icon)
                .font(.subheadline.bold())
            Spacer()
            Image(systemName: "square.and.arrow.up")
                .font(.caption)
                .foregroundStyle(AppTheme.textMuted)
        }
        .foregroundStyle(AppTheme.primaryText(for: colorScheme))
        .padding(14)
        .background(AppTheme.cardBackground(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func saveCard() {
        appState.digitalCard.save(draft, for: userId)
        savedMessage = "Digital card saved."
        shareImage = appState.digitalCard.renderShareImage(card: draft, colorScheme: colorScheme)
        Haptic.success()
    }
}

struct DigitalBusinessCardPreview: View {
    let card: DigitalBusinessCard
    let colorScheme: ColorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: card.theme.gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 120)

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        AppLogo(size: 36, showGlow: false, cornerRadius: 8)
                        Spacer()
                        Image(systemName: "person.text.rectangle.fill")
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    Text(card.fullName.isEmpty ? "Your Name" : card.fullName)
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                    if !card.title.isEmpty {
                        Text(card.title)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.9))
                            .lineLimit(1)
                    }
                }
                .padding(18)
            }

            VStack(alignment: .leading, spacing: 10) {
                if !card.company.isEmpty {
                    cardRow("building.2.fill", card.company)
                }
                if !card.phone.isEmpty {
                    cardRow("phone.fill", card.phone)
                }
                if !card.email.isEmpty {
                    cardRow("envelope.fill", card.email)
                }
                if !card.website.isEmpty {
                    cardRow("globe", card.website)
                }
                if !card.linkedIn.isEmpty {
                    cardRow("link", card.linkedIn)
                }
                if !card.tagline.isEmpty {
                    Text(card.tagline)
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                        .lineLimit(3)
                        .padding(.top, 4)
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.cardBackground(for: colorScheme))
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(card.theme.accent.opacity(0.35), lineWidth: 1)
        }
        .shadow(color: card.theme.accent.opacity(0.2), radius: 12, y: 6)
    }

    private func cardRow(_ icon: String, _ value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(card.theme.accent)
                .frame(width: 18)
            Text(value)
                .font(.subheadline)
                .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                .lineLimit(2)
                .minimumScaleFactor(0.85)
        }
    }
}
