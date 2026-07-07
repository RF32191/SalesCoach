import CoreImage.CIFilterBuiltins
import Foundation
import SwiftUI

@MainActor
@Observable
final class DigitalBusinessCardService {
    private(set) var card: DigitalBusinessCard?

    private func storageKey(for userId: String) -> String {
        "salescoach_digital_card_\(userId)"
    }

    func load(for userId: String, profile: UserProfile?) {
        if let data = UserDefaults.standard.data(forKey: storageKey(for: userId)),
           let stored = try? JSONDecoder().decode(DigitalBusinessCard.self, from: data),
           stored.userId == userId {
            card = stored
        } else if let profile {
            card = DigitalBusinessCard.fromProfile(profile)
        } else {
            card = DigitalBusinessCard(userId: userId)
        }
    }

    func save(_ card: DigitalBusinessCard, for userId: String) {
        var updated = card
        updated.updatedAt = .now
        self.card = updated
        if let data = try? JSONEncoder().encode(updated) {
            UserDefaults.standard.set(data, forKey: storageKey(for: userId))
        }
    }

    func syncFromProfile(_ profile: UserProfile) {
        guard var existing = card, existing.userId == profile.id else {
            card = DigitalBusinessCard.fromProfile(profile)
            return
        }
        if existing.fullName.isEmpty { existing.fullName = profile.fullName }
        if existing.email.isEmpty { existing.email = profile.email }
        if existing.company.isEmpty { existing.company = profile.companyName ?? "" }
        card = existing
    }

    func qrImage(for card: DigitalBusinessCard, size: CGFloat = 160) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(card.qrPayload.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 8, y: 8))
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    @MainActor
    func renderShareImage(card: DigitalBusinessCard, colorScheme: ColorScheme) -> UIImage? {
        let content = DigitalBusinessCardPreview(card: card, colorScheme: colorScheme)
            .frame(width: 340)
            .padding(20)
            .background(AppTheme.background(for: colorScheme))
        let renderer = ImageRenderer(content: content)
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage
    }
}
