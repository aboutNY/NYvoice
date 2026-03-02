import Foundation

struct AppSettings: Codable, Equatable {
    var shortcut: ShortcutDefinition
    var whisperBinaryPath: String
    var whisperModelPath: String
    var ollamaModel: String
    var ollamaPromptTemplate: String
    var correctionEnabled: Bool

    static let `default` = AppSettings(
        shortcut: .default,
        whisperBinaryPath: "/usr/local/bin/whisper-cli",
        whisperModelPath: "",
        ollamaModel: "qwen2.5:7b",
        ollamaPromptTemplate: """
        次の日本語テキストの誤字脱字・変換ミスのみを修正してください。
        意味を変えず、要約せず、修正後テキストのみを返してください。
        ---
        {{transcript}}
        """,
        correctionEnabled: true
    )

    init(
        shortcut: ShortcutDefinition,
        whisperBinaryPath: String,
        whisperModelPath: String,
        ollamaModel: String,
        ollamaPromptTemplate: String,
        correctionEnabled: Bool
    ) {
        self.shortcut = shortcut
        self.whisperBinaryPath = whisperBinaryPath
        self.whisperModelPath = whisperModelPath
        self.ollamaModel = ollamaModel
        self.ollamaPromptTemplate = ollamaPromptTemplate
        self.correctionEnabled = correctionEnabled
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = AppSettings.default
        shortcut = try container.decodeIfPresent(ShortcutDefinition.self, forKey: .shortcut) ?? defaults.shortcut
        whisperBinaryPath = try container.decodeIfPresent(String.self, forKey: .whisperBinaryPath) ?? defaults.whisperBinaryPath
        whisperModelPath = try container.decodeIfPresent(String.self, forKey: .whisperModelPath) ?? defaults.whisperModelPath
        ollamaModel = try container.decodeIfPresent(String.self, forKey: .ollamaModel) ?? defaults.ollamaModel
        ollamaPromptTemplate = try container.decodeIfPresent(String.self, forKey: .ollamaPromptTemplate) ?? defaults.ollamaPromptTemplate
        correctionEnabled = try container.decodeIfPresent(Bool.self, forKey: .correctionEnabled) ?? defaults.correctionEnabled
    }
}
