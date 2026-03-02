import AppKit
import SwiftUI

@MainActor
struct SettingsView: View {
    private enum SettingsTab: String, CaseIterable, Identifiable {
        case transcription = "音声認識モデル"
        case llmCorrection = "LLM修正"

        var id: String { rawValue }
    }

    @State private var settings: AppSettings
    @State private var selectedTab: SettingsTab = .transcription
    @State private var validationMessage = ""
    private let container: AppContainer

    init(container: AppContainer) {
        self.container = container
        _settings = State(initialValue: container.sessionController.currentSettings())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Picker("設定カテゴリ", selection: $selectedTab) {
                ForEach(SettingsTab.allCases) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)

            Group {
                switch selectedTab {
                case .transcription:
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Whisper Binary Path")
                            .font(.headline)
                        TextField("/opt/homebrew/bin/whisper-cli", text: $settings.whisperBinaryPath)
                            .textFieldStyle(.roundedBorder)
                        Text("Whisper Model Path")
                            .font(.headline)
                        TextField("/Users/username/models/ggml-*.bin", text: $settings.whisperModelPath)
                            .textFieldStyle(.roundedBorder)
                    }
                case .llmCorrection:
                    VStack(alignment: .leading, spacing: 10) {
                        Toggle("Enable Correction", isOn: $settings.correctionEnabled)
                        Text("Ollama Model")
                            .font(.headline)
                        TextField("qwen2.5:7b", text: $settings.ollamaModel)
                            .textFieldStyle(.roundedBorder)
                        Text("Ollama Prompt Template")
                            .font(.headline)
                        TextEditor(text: $settings.ollamaPromptTemplate)
                            .font(.body.monospaced())
                            .frame(minHeight: 190)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.secondary.opacity(0.25), lineWidth: 1)
                            )
                        Text("Use {{transcript}} as the transcript placeholder.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)

            Spacer(minLength: 0)

            HStack {
                Text("Recording shortcut: Double-press Alt (Option) key")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Current state: \(container.sessionController.state.rawValue)")
                    .foregroundStyle(.secondary)
            }

            if !validationMessage.isEmpty {
                Text(validationMessage)
                    .font(.footnote)
                    .foregroundStyle(Color.secondary)
            }

            HStack {
                Spacer()
                Button("Save") {
                    container.updateSettings(settings)
                    validationMessage = "Saved"
                }
            }
        }
        .padding(16)
        .frame(minWidth: 720, minHeight: 500)
    }
}
