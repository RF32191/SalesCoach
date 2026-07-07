import AVFoundation
import Foundation
import UIKit
import Vision

struct ScannedContact: Equatable {
    var name: String = ""
    var company: String = ""
    var phone: String = ""
    var email: String = ""
    var title: String = ""
    var website: String = ""
    var rawText: String = ""
}

enum BusinessCardScannerService {
    static func parseContact(from text: String) -> ScannedContact {
        var contact = ScannedContact(rawText: text)
        let lines = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if let email = firstMatch(in: text, pattern: #"[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}"#) {
            contact.email = email
        }
        if let phone = firstMatch(in: text, pattern: #"(?:\+?\d{1,3}[\s.-]?)?\(?\d{3}\)?[\s.-]?\d{3}[\s.-]?\d{4}"#) {
            contact.phone = phone
        }
        if let website = firstMatch(in: text, pattern: #"(?:https?://)?(?:www\.)?[a-z0-9.-]+\.[a-z]{2,}(?:/[^\s]*)?"#, options: .caseInsensitive) {
            contact.website = website
        }

        let titleKeywords = ["ceo", "president", "director", "manager", "vp", "founder", "owner", "sales", "partner"]
        for line in lines {
            let lower = line.lowercased()
            if line == contact.email || line == contact.phone || line == contact.website { continue }
            if titleKeywords.contains(where: { lower.contains($0) }) && contact.title.isEmpty {
                contact.title = line
                continue
            }
            if contact.company.isEmpty, line.count > 3,
               !lower.contains("@"), !lower.contains("www"), !lower.allSatisfy(\.isNumber) {
                if contact.name.isEmpty && line.split(separator: " ").count <= 4 {
                    contact.name = line
                } else if contact.company.isEmpty {
                    contact.company = line
                }
            }
        }

        if contact.name.isEmpty, let first = lines.first(where: { !$0.contains("@") && !$0.contains("http") }) {
            contact.name = first
        }
        if contact.company.isEmpty {
            contact.company = lines.dropFirst().first(where: { $0 != contact.name && $0 != contact.title }) ?? ""
        }
        return contact
    }

    static func recognizeText(in image: UIImage) async -> String {
        guard let cgImage = image.cgImage else { return "" }
        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, _ in
                let strings = (request.results as? [VNRecognizedTextObservation])?
                    .compactMap { $0.topCandidates(1).first?.string } ?? []
                continuation.resume(returning: strings.joined(separator: "\n"))
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }
    }

    static func cameraAuthorized() -> Bool {
        AVCaptureDevice.authorizationStatus(for: .video) == .authorized
    }

    static func requestCameraAccess() async -> Bool {
        await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .video) { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    private static func firstMatch(in text: String, pattern: String, options: NSRegularExpression.Options = [.caseInsensitive]) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, range: range),
              let swiftRange = Range(match.range, in: text) else { return nil }
        return String(text[swiftRange])
    }
}
