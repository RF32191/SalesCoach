import AVFoundation
import Foundation

struct VoiceSettings: Codable, Equatable {
    var languageId: String
    var accentVoiceId: String?
    var speechRate: Float
    var autoSpeakResponses: Bool
    var useAIVoice: Bool
    var openAIVoiceId: String
    var aiSpeechSpeed: Double
    var usePersonalityVoice: Bool
    var ttsModel: String

    var language: VoiceLanguageOption {
        VoiceLanguageOption.supported.first { $0.id == languageId } ?? .englishUS
    }

    static let `default` = VoiceSettings(
        languageId: VoiceLanguageOption.englishUS.id,
        accentVoiceId: nil,
        speechRate: 0.48,
        autoSpeakResponses: true,
        useAIVoice: true,
        openAIVoiceId: OpenAIVoiceOption.shimmer.rawValue,
        aiSpeechSpeed: 0.94,
        usePersonalityVoice: true,
        ttsModel: OpenAITTSModel.hd.rawValue
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
            .sorted { lhs, rhs in
                let lhsScore = lhs.qualityScore
                let rhsScore = rhs.qualityScore
                if lhsScore != rhsScore { return lhsScore > rhsScore }
                return lhs.name < rhs.name
            }
            .map { VoiceAccentOption(label: $0.displayLabel, voiceIdentifier: $0.identifier) }
    }
}

extension AVSpeechSynthesisVoice {
    var qualityScore: Int {
        if #available(iOS 16.0, *), quality == .premium { return 3 }
        if #available(iOS 16.0, *), quality == .enhanced { return 2 }
        return 1
    }

    var displayLabel: String {
        if #available(iOS 16.0, *), quality == .premium { return "\(name) (Premium)" }
        if #available(iOS 16.0, *), quality == .enhanced { return "\(name) (Enhanced)" }
        return name
    }
}

struct RoleplayTurnResult: Equatable {
    let customerReply: String
    let closingProgressDelta: Int
    let suggestion: String
}

enum OpenAITTSModel: String, Codable, CaseIterable, Identifiable {
    case standard = "tts-1"
    case hd = "tts-1-hd"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .standard: "Standard"
        case .hd: "HD (Recommended)"
        }
    }

    var description: String {
        switch self {
        case .standard: "Fast, lower latency"
        case .hd: "Richer, more natural customer voice"
        }
    }
}

enum OpenAIVoiceOption: String, Codable, CaseIterable, Identifiable {
    case alloy, echo, fable, onyx, nova, shimmer

    var id: String { rawValue }

    var label: String {
        rawValue.capitalized
    }

    var description: String {
        switch self {
        case .alloy: "Calm and conversational"
        case .echo: "Warm executive tone"
        case .fable: "Expressive storyteller"
        case .onyx: "Deep and authoritative"
        case .nova: "Friendly and approachable"
        case .shimmer: "Natural and lifelike"
        }
    }

    var previewLine: String {
        switch self {
        case .alloy: "I hear you. Walk me through how this would actually help my team."
        case .echo: "You've got thirty seconds — what's the bottom line for my business?"
        case .fable: "I've been burned before, so you'll need to earn my trust here."
        case .onyx: "We're already working with someone. Convince me why I should switch."
        case .nova: "This sounds interesting — tell me more about how onboarding works."
        case .shimmer: "I'm open to it, but I need to understand pricing before we go further."
        }
    }
}

extension CustomerPersonality {
    var recommendedVoice: OpenAIVoiceOption {
        switch self {
        case .angry: .onyx
        case .budgetConscious: .alloy
        case .interested: .shimmer
        case .skeptical: .echo
        case .busyExecutive: .onyx
        case .competitorLoyal: .fable
        case .firstTimeBuyer: .nova
        }
    }

    var recommendedSpeechSpeed: Double {
        switch self {
        case .angry: 0.90
        case .budgetConscious: 0.94
        case .interested: 0.97
        case .skeptical: 0.92
        case .busyExecutive: 1.02
        case .competitorLoyal: 0.93
        case .firstTimeBuyer: 0.96
        }
    }
}
