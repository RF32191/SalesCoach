import AVFoundation
import Speech

@MainActor
@Observable
final class VoiceService: NSObject {
    var isListening = false
    var isSpeaking = false
    var transcribedText = ""
    var errorMessage: String?
    var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    var settings: VoiceSettings {
        didSet { saveSettings() }
    }

    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private let synthesizer = AVSpeechSynthesizer()
    private let settingsKey = "salescoach_voice_settings"

    override init() {
        settings = Self.loadSettings()
        super.init()
        synthesizer.delegate = self
        applyLanguageSettings()
    }

    func requestPermissions() async {
        authorizationStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }

        let micGranted = await AVAudioApplication.requestRecordPermission()
        if !micGranted {
            errorMessage = "Microphone access is required for voice roleplay."
        }
    }

    func updateLanguage(_ language: VoiceLanguageOption) {
        settings.languageId = language.id
        settings.accentVoiceId = VoiceAccentOption.accents(for: language).first?.voiceIdentifier
        applyLanguageSettings()
    }

    func updateAccent(_ accent: VoiceAccentOption) {
        settings.accentVoiceId = accent.voiceIdentifier
    }

    func applyLanguageSettings() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: settings.language.localeIdentifier))
    }

    func startListening() throws {
        guard authorizationStatus == .authorized else {
            errorMessage = "Speech recognition not authorized."
            return
        }

        stopListening()
        transcribedText = ""
        errorMessage = nil

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetooth])
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest, let speechRecognizer, speechRecognizer.isAvailable else {
            errorMessage = "Speech recognition unavailable for \(settings.language.label)."
            return
        }

        recognitionRequest.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor in
                if let result {
                    self?.transcribedText = result.bestTranscription.formattedString
                }
                if error != nil || result?.isFinal == true {
                    self?.stopListeningInternal()
                }
            }
        }

        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()
        isListening = true
    }

    func stopListening() {
        stopListeningInternal()
    }

    private func stopListeningInternal() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        isListening = false
    }

    @discardableResult
    func speak(_ text: String) async -> Bool {
        guard !text.isEmpty, settings.autoSpeakResponses else { return false }

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker, .allowBluetooth])
        try? audioSession.setActive(true)

        let utterance = AVSpeechUtterance(string: text)
        if let accentId = settings.accentVoiceId,
           let voice = AVSpeechSynthesisVoice(identifier: accentId) {
            utterance.voice = voice
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: settings.language.localeIdentifier)
        }
        utterance.rate = settings.speechRate
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0

        isSpeaking = true
        synthesizer.speak(utterance)

        return await withCheckedContinuation { continuation in
            self.speakContinuation = continuation
        }
    }

    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
        speakContinuation?.resume(returning: false)
        speakContinuation = nil
    }

    private var speakContinuation: CheckedContinuation<Bool, Never>?

    private func saveSettings() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: settingsKey)
        }
    }

    private static func loadSettings() -> VoiceSettings {
        guard let data = UserDefaults.standard.data(forKey: "salescoach_voice_settings"),
              let stored = try? JSONDecoder().decode(VoiceSettings.self, from: data) else {
            return .default
        }
        return stored
    }
}

extension VoiceService: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            isSpeaking = false
            speakContinuation?.resume(returning: true)
            speakContinuation = nil
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            isSpeaking = false
            speakContinuation?.resume(returning: false)
            speakContinuation = nil
        }
    }
}
