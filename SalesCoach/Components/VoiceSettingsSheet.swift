import SwiftUI

struct VoiceSettingsSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var selectedLanguage: VoiceLanguageOption
    @State private var selectedAccentId: String?
    @State private var speechRate: Float
    @State private var autoSpeak: Bool

    init(voice: VoiceService) {
        _selectedLanguage = State(initialValue: voice.settings.language)
        _selectedAccentId = State(initialValue: voice.settings.accentVoiceId)
        _speechRate = State(initialValue: voice.settings.speechRate)
        _autoSpeak = State(initialValue: voice.settings.autoSpeakResponses)
    }

    private var accents: [VoiceAccentOption] {
        VoiceAccentOption.accents(for: selectedLanguage)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Language") {
                    Picker("Language", selection: $selectedLanguage) {
                        ForEach(VoiceLanguageOption.supported) { language in
                            Text(language.label).tag(language)
                        }
                    }
                    .onChange(of: selectedLanguage) { _, newValue in
                        appState.voice.updateLanguage(newValue)
                        selectedAccentId = VoiceAccentOption.accents(for: newValue).first?.voiceIdentifier
                    }
                }

                Section("Accent / Voice") {
                    if accents.isEmpty {
                        Text("No voices available for this language.")
                            .foregroundStyle(AppTheme.textSecondary)
                    } else {
                        Picker("Accent", selection: $selectedAccentId) {
                            ForEach(accents) { accent in
                                Text(accent.label).tag(Optional(accent.voiceIdentifier))
                            }
                        }
                    }
                }

                Section("Speech") {
                    Toggle("AI speaks responses aloud", isOn: $autoSpeak)
                    VStack(alignment: .leading) {
                        Text("Speaking speed")
                            .font(.subheadline)
                        Slider(value: $speechRate, in: 0.35...0.55)
                        Text(speechRate < 0.45 ? "Slower" : speechRate > 0.52 ? "Faster" : "Normal")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }

                Section {
                    Button("Test Voice") {
                        Task {
                            appState.voice.settings.speechRate = speechRate
                            appState.voice.settings.autoSpeakResponses = true
                            if let accentId = selectedAccentId {
                                appState.voice.settings.accentVoiceId = accentId
                            }
                            await appState.voice.speak("Hi, I'm your AI sales customer. Let's practice closing this deal.")
                        }
                    }
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

    private func save() {
        appState.voice.settings.languageId = selectedLanguage.id
        appState.voice.settings.accentVoiceId = selectedAccentId
        appState.voice.settings.speechRate = speechRate
        appState.voice.settings.autoSpeakResponses = autoSpeak
        appState.voice.applyLanguageSettings()
        dismiss()
    }
}
