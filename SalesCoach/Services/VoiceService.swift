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
    var onTokensUsed: ((Int) -> Void)?
    var onUtteranceFinished: ((String) -> Void)?
    var settings: VoiceSettings {
        didSet { saveSettings() }
    }

    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private let synthesizer = AVSpeechSynthesizer()
    private var audioPlayer: AVAudioPlayer?
    private var silenceDetectionTask: Task<Void, Never>?
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
                guard let self else { return }
                if let result {
                    self.transcribedText = result.bestTranscription.formattedString
                    self.scheduleSilenceDetection()
                    if result.isFinal {
                        self.finishCurrentUtterance()
                    }
                } else if error != nil {
                    self.finishCurrentUtterance()
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
        finishCurrentUtterance()
    }

    func cancelListening() {
        silenceDetectionTask?.cancel()
        silenceDetectionTask = nil
        transcribedText = ""
        stopListeningInternal()
    }

    private func scheduleSilenceDetection() {
        silenceDetectionTask?.cancel()
        silenceDetectionTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.6))
            guard !Task.isCancelled, isListening else { return }
            finishCurrentUtterance()
        }
    }

    private func finishCurrentUtterance() {
        silenceDetectionTask?.cancel()
        silenceDetectionTask = nil
        guard isListening else { return }

        let text = transcribedText.trimmingCharacters(in: .whitespacesAndNewlines)
        stopListeningInternal()
        transcribedText = ""

        guard !text.isEmpty else { return }
        onUtteranceFinished?(text)
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
    func speak(_ text: String, force: Bool = false, personality: CustomerPersonality? = nil) async -> Bool {
        guard !text.isEmpty, force || settings.autoSpeakResponses else { return false }

        let spokenText = Self.naturalizeSpeechText(text)

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        audioPlayer?.stop()

        if settings.useAIVoice && AppConfig.isAIConfigured {
            if await speakWithOpenAI(spokenText, personality: personality) {
                return true
            }
        }

        return await speakWithSystemVoice(spokenText, personality: personality)
    }

    private func speakWithOpenAI(_ text: String, personality: CustomerPersonality?) async -> Bool {
        let voice = resolvedAIVoice(for: personality)
        let speed = resolvedAISpeed(for: personality)

        do {
            let data = try await OpenAIService.shared.synthesizeSpeech(
                text: text,
                voice: voice,
                speed: speed,
                model: settings.ttsModel
            )
            return await playAudioData(data)
        } catch {
            errorMessage = "AI voice unavailable, using system voice."
            return false
        }
    }

    private func resolvedAIVoice(for personality: CustomerPersonality?) -> String {
        if settings.usePersonalityVoice, let personality {
            return personality.recommendedVoice.rawValue
        }
        return settings.openAIVoiceId
    }

    private func resolvedAISpeed(for personality: CustomerPersonality?) -> Double {
        if settings.usePersonalityVoice, let personality {
            return personality.recommendedSpeechSpeed
        }
        return settings.aiSpeechSpeed
    }

    static func naturalizeSpeechText(_ text: String) -> String {
        var cleaned = text
            .replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "__", with: "")
            .replacingOccurrences(of: "`", with: "")
            .replacingOccurrences(of: "\n", with: ". ")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        cleaned = cleaned.replacingOccurrences(
            of: #"^\s*[-•]\s*"#,
            with: "",
            options: .regularExpression
        )

        if !cleaned.isEmpty, !".!?".contains(cleaned.last!) {
            cleaned += "."
        }

        return cleaned
    }

    private func speakWithSystemVoice(_ text: String, personality: CustomerPersonality?) async -> Bool {
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker, .allowBluetooth])
        try? audioSession.setActive(true)

        let utterance = AVSpeechUtterance(string: text)
        if let accentId = settings.accentVoiceId,
           let voice = AVSpeechSynthesisVoice(identifier: accentId) {
            utterance.voice = voice
        } else {
            utterance.voice = Self.bestSystemVoice(for: settings.language.localeIdentifier)
        }

        utterance.rate = settings.speechRate
        utterance.pitchMultiplier = personalityPitchMultiplier(for: personality)
        utterance.volume = 1.0
        utterance.preUtteranceDelay = 0.05
        utterance.postUtteranceDelay = 0.08

        isSpeaking = true
        synthesizer.speak(utterance)

        return await withCheckedContinuation { continuation in
            self.speakContinuation = continuation
        }
    }

    private func personalityPitchMultiplier(for personality: CustomerPersonality?) -> Float {
        guard let personality else { return 1.0 }
        switch personality {
        case .angry, .busyExecutive: return 0.94
        case .firstTimeBuyer, .interested: return 1.04
        case .budgetConscious: return 0.98
        default: return 1.0
        }
    }

    private static func bestSystemVoice(for localeIdentifier: String) -> AVSpeechSynthesisVoice? {
        let prefix = String(localeIdentifier.prefix(2))
        let voices = AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.hasPrefix(prefix) }
            .sorted { $0.qualityScore > $1.qualityScore }
        return voices.first ?? AVSpeechSynthesisVoice(language: localeIdentifier)
    }

    private func playAudioData(_ data: Data) async -> Bool {
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker, .allowBluetooth])
        try? audioSession.setActive(true)

        do {
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.delegate = self
            audioPlayer?.volume = 1.0
            audioPlayer?.enableRate = true
            audioPlayer?.rate = 1.0
            audioPlayer?.prepareToPlay()
            isSpeaking = true
            audioPlayer?.play()

            return await withCheckedContinuation { continuation in
                self.playContinuation = continuation
            }
        } catch {
            isSpeaking = false
            return false
        }
    }

    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
        audioPlayer?.stop()
        isSpeaking = false
        speakContinuation?.resume(returning: false)
        speakContinuation = nil
        playContinuation?.resume(returning: false)
        playContinuation = nil
    }

    private var speakContinuation: CheckedContinuation<Bool, Never>?
    private var playContinuation: CheckedContinuation<Bool, Never>?

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

extension VoiceService: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            isSpeaking = false
            playContinuation?.resume(returning: flag)
            playContinuation = nil
        }
    }

    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor in
            isSpeaking = false
            playContinuation?.resume(returning: false)
            playContinuation = nil
        }
    }
}
