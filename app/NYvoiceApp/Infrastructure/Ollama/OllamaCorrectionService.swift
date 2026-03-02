import Foundation

final class OllamaCorrectionService: CorrectionService {
    private let endpoint = URL(string: "http://127.0.0.1:11434/api/generate")!
    private let transcriptPlaceholder = "{{transcript}}"

    func correct(text: String, settings: AppSettings) async throws -> String {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let prompt = buildPrompt(transcript: text, settings: settings)

        let body: [String: Any] = [
            "model": settings.ollamaModel,
            "prompt": prompt,
            "stream": false
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw DomainError.correction("Ollama request failed")
        }

        guard
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let corrected = json["response"] as? String,
            !corrected.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            throw DomainError.correction("Invalid Ollama response")
        }

        return corrected.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func buildPrompt(transcript: String, settings: AppSettings) -> String {
        let template = settings.ollamaPromptTemplate.trimmingCharacters(in: .whitespacesAndNewlines)
        if template.isEmpty {
            return transcript
        }

        if template.contains(transcriptPlaceholder) {
            return template.replacingOccurrences(of: transcriptPlaceholder, with: transcript)
        }

        return "\(template)\n---\n\(transcript)"
    }
}
