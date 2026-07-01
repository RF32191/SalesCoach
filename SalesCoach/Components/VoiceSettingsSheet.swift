import SwiftUI

struct VoiceSettingsSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var selectedLanguage: VoiceLanguageOption
    @State private var selectedAccentId: String?
    @State private var speechRate: Float
    @State private var autoSpeak: Bool
    @State private var useAIVoice: Bool
    @State private var selectedAIVoice: OpenAIVoiceOption
    @State private var aiSpeechSpeed: Double
    @State private var usePersonalityVoice: Bool
    @State private var selectedTTSModel: OpenAITTSModel
    @State private var isPreviewing = false

    init(voice: VoiceService) {
        _selectedLanguage = State(initialValue: voice.settings.language)
        _selectedAccentId = State(initialValue: voice.settings.accentVoiceId)
        _speechRate = State(initialValue: voice.settings.speechRate)
        _autoSpeak = State(initialValue: voice.settings.autoSpeakResponses)
        _useAIVoice = State(initialValue: voice.settings.useAIVoice)
        _selectedAIVoice = State(initialValue: OpenAIVoiceOption(rawValue: voice.settings.openAIVoiceId) ?? .shimmer)
        _aiSpeechSpeed = State(initialValue: voice.settings.aiSpeechSpeed)
        _usePersonalityVoice = State(initialValue: voice.settings.usePersonalityVoice)
        _selectedTTSModel = State(initialValue: OpenAITTSModel(rawValue: voice.settings.ttsModel) ?? .hd)
    }

    private var accents: [VoiceAccentOption] {
        VoiceAccentOption.accents(for: selectedLanguage)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Use natural AI voice", isOn: $useAIVoice)
                    Toggle("Match voice to customer personality", isOn: $usePersonalityVoice)
                    if !AppConfig.isAIConfigured {
                        Text("Requires Railway or OpenAI API configured.")
                            .font(.caption)
                            .foregroundStyle(AppTheme.warningOrange)
                    }
                } header: {
                    Text("AI Voice")
                } footer: {
                    Text("Personality matching gives angry customers a deeper tone, executives a faster pace, and warm leads a friendly shimmer voice.")
                }

                if useAIVoice {
                    Section("Voice Quality") {
                        Picker("Model", selection: $selectedTTSModel) {
                            ForEach(OpenAITTSModel.allCases) { model in
                                Text("\(model.label) — \(model.description)").tag(model)
                            }
                        }
                    }

                    if !usePersonalityVoice {
                        Section("Default Customer Voice") {
                            Picker("Voice", selection: $selectedAIVoice) {
                                ForEach(OpenAIVoiceOption.allCases) { voice in
                                    Text("\(voice.label) — \(voice.description)").tag(voice)
                                }
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Speech pace")
                                Slider(value: $aiSpeechSpeed, in: 0.82...1.08)
                                Text(String(format: "%.2fx", aiSpeechSpeed))
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.textMuted)
                            }
                        }
                    }
                }

                Section("System Voice Fallback") {
                    Picker("Language", selection: $selectedLanguage) {
                        ForEach(VoiceLanguageOption.supported) { language in
                            Text(language.label).tag(language)
                        }
                    }
                    .onChange(of: selectedLanguage) { _, newValue in
                        appState.voice.updateLanguage(newValue)
                        selectedAccentId = VoiceAccentOption.accents(for: newValue).first?.voiceIdentifier
                    }

                    if accents.isEmpty {
                        Text("No system voices available for this language.")
                            .foregroundStyle(AppTheme.textSecondary)
                    } else {
                        Picker("Accent", selection: $selectedAccentId) {
                            ForEach(accents) { accent in
                                Text(accent.label).tag(Optional(accent.voiceIdentifier))
                            }
                        }
                    }

                    VStack(alignment: .leading) {
                        Text("System speaking speed")
                        Slider(value: $speechRate, in: 0.35...0.55)
                    }
                }

                Section("Behavior") {
                    Toggle("AI speaks responses aloud", isOn: $autoSpeak)
                }

                Section {
                    Button {
                        previewVoice()
                    } label: {
                        HStack {
                            Text("Preview Voice")
                            Spacer()
                            if isPreviewing {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isPreviewing)
                }
            }
            .navigationTitle("Voice Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
        }
    }

    private func previewVoice() {
        isPreviewing = true
        saveDraftSettings()
        Task {
            let line = usePersonalityVoice
                ? CustomerPersonality.skeptical.recommendedVoice.previewLine
                : selectedAIVoice.previewLine
            await appState.voice.speak(line, force: true, personality: usePersonalityVoice ? .skeptical : nil)
            isPreviewing = false
        }
    }

    private func saveDraftSettings() {
        appState.voice.settings.languageId = selectedLanguage.id
        appState.voice.settings.accentVoiceId = selectedAccentId
        appState.voice.settings.speechRate = speechRate
        appState.voice.settings.autoSpeakResponses = autoSpeak
        appState.voice.settings.useAIVoice = useAIVoice
        appState.voice.settings.openAIVoiceId = selectedAIVoice.rawValue
        appState.voice.settings.aiSpeechSpeed = aiSpeechSpeed
        appState.voice.settings.usePersonalityVoice = usePersonalityVoice
        appState.voice.settings.ttsModel = selectedTTSModel.rawValue
        appState.voice.applyLanguageSettings()
    }

    private func save() {
        saveDraftSettings()
        dismiss()
    }
}
