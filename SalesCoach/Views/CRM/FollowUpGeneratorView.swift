import SwiftUI

struct FollowUpGeneratorView: View {
    @Environment(\.dismiss) private var dismiss
    let lead: Lead

    @State private var selectedType: FollowUpType = .email
    @State private var generatedContent = ""
    @State private var isGenerating = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Picker("Type", selection: $selectedType) {
                    ForEach(FollowUpType.allCases) { type in
                        Label(type.rawValue, systemImage: type.icon).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                if isGenerating {
                    Spacer()
                    ProgressView("Generating...")
                        .tint(AppTheme.electricBlue)
                        .foregroundStyle(AppTheme.textSecondary)
                    Spacer()
                } else if generatedContent.isEmpty {
                    Spacer()
                    Image(systemName: selectedType.icon)
                        .font(.system(size: 48))
                        .foregroundStyle(AppTheme.electricBlue)
                    Text("Generate a \(selectedType.rawValue.lowercased()) for \(lead.name)")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding()
                    Spacer()
                    PrimaryButton(title: "Generate", icon: "sparkles") {
                        generate()
                    }
                    .padding()
                } else {
                    ScrollView {
                        Text(generatedContent)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(AppTheme.navyCard)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal)
                    }

                    HStack(spacing: 12) {
                        SecondaryButton(title: "Regenerate", icon: "arrow.clockwise") {
                            generate()
                        }
                        PrimaryButton(title: "Copy", icon: "doc.on.doc") {
                            #if os(iOS)
                            UIPasteboard.general.string = generatedContent
                            #endif
                        }
                    }
                    .padding()
                }
            }
            .appBackground()
            .navigationTitle("AI Follow-Up")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func generate() {
        isGenerating = true
        generatedContent = ""
        Task {
            if let content = try? await OpenAIService.shared.generateFollowUp(type: selectedType, lead: lead) {
                generatedContent = content
            }
            isGenerating = false
        }
    }
}

#if os(iOS)
import UIKit
#endif
