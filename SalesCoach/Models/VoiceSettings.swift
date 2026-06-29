import AVFoundation
import Foundation

struct VoiceSettings: Codable, Equatable {
    var languageId: String
    var accentVoiceId: String?
    var speechRate: Float
    var autoSpeakResponses: Bool

    var language: VoiceLanguageOption {
        VoiceLanguageOption.supported.first { $0.id == languageId } ?? .englishUS
    }

    static let `default` = VoiceSettings(
        languageId: VoiceLanguageOption.englishUS.id,
        accentVoiceId: nil,
        speechRate: AVSpeechUtteranceDefaultSpeechRate,
        autoSpeakResponses: true
    )
}

enum VoiceLanguageOption: String, Codable, CaseIterable, Identifiable {
    case englishUS = "en-US"
    case englishUK = "en-GB"
    case spanish = "es-ES"
    case french = "fr-FR"
    case german = "de-DE"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .englishUS: "English (US)"
        case .englishUK: "English (UK)"
        case .spanish: "Spanish"
        case .french: "French"
        case .german: "German"
        }
    }

    var localeIdentifier: String { rawValue }

    static let supported: [VoiceLanguageOption] = allCases
}

struct VoiceAccentOption: Identifiable, Equatable {
    var id: String { voiceIdentifier }
    let label: String
    let voiceIdentifier: String

    static func accents(for language: VoiceLanguageOption) -> [VoiceAccentOption] {
        AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.hasPrefix(String(language.localeIdentifier.prefix(2))) }
            .map { VoiceAccentOption(label: $0.name, voiceIdentifier: $0.identifier) }
            .sorted { $0.label < $1.label }
    }
}

struct RoleplayTurnResult: Equatable {
    let customerReply: String
    let closingProgressDelta: Int
    let suggestion: String
}
