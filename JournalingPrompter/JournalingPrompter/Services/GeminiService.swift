import Foundation

actor GeminiService {
    static let shared = GeminiService(apiKey: UserDefaults.standard.string(forKey: "geminiAPIKey") ?? "")

    private let apiKey: String
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent"

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func generateReflectionPrompt() async throws -> String {
        let systemPrompt = """
        Write a simple evening journaling question to help someone reflect on their day.

        Rules:
        - Use simple, everyday words (5th grade reading level)
        - One short question only (under 15 words)
        - Help them think about their day meaningfully
        - Sound like a friend, not a therapist

        Good examples:
        - "What moment from today do you want to remember?"
        - "What made you proud of yourself today?"
        - "What's one thing you'd do differently?"
        - "Who made your day a little better?"

        Reply with ONLY the question.
        """

        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": systemPrompt]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.9,
                "maxOutputTokens": 100
            ]
        ]

        guard let url = URL(string: "\(baseURL)?key=\(apiKey)") else {
            throw GeminiError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw GeminiError.httpError(statusCode: httpResponse.statusCode)
        }

        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)

        guard let parts = geminiResponse.candidates?.first?.content?.parts else {
            throw GeminiError.noContent
        }

        let fullText = parts.compactMap { $0.text }.joined()

        guard !fullText.isEmpty else {
            throw GeminiError.noContent
        }

        return fullText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func generatePrompt(
        mood: Mood,
        activities: [Activity],
        timeOfDay: TimeOfDay
    ) async throws -> String {
        let systemPrompt = buildSystemPrompt(mood: mood, activities: activities, timeOfDay: timeOfDay)

        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": systemPrompt]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.8,
                "maxOutputTokens": 500
            ]
        ]

        guard let url = URL(string: "\(baseURL)?key=\(apiKey)") else {
            throw GeminiError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw GeminiError.httpError(statusCode: httpResponse.statusCode)
        }

        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)

        // Combine all text parts from the response
        guard let parts = geminiResponse.candidates?.first?.content?.parts else {
            throw GeminiError.noContent
        }

        let fullText = parts.compactMap { $0.text }.joined()

        guard !fullText.isEmpty else {
            throw GeminiError.noContent
        }

        return fullText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func buildSystemPrompt(mood: Mood, activities: [Activity], timeOfDay: TimeOfDay) -> String {
        let activitiesList = activities.map { $0.rawValue.lowercased() }.joined(separator: ", ")

        return """
        Write a simple journaling question for someone who did: \(activitiesList). They feel \(mood.rawValue.lowercased()).

        Rules:
        - Use simple, everyday words (5th grade reading level)
        - One short question only (under 15 words)
        - Be specific to their activity
        - Sound like a friend, not a therapist

        Good examples:
        - "What made you laugh today?"
        - "Who made your day better?"
        - "What tired you out the most?"
        - "What are you proud of from today?"
        - "What's stuck in your head right now?"

        Bad examples (too formal):
        - "What insights emerged from your professional endeavors?"
        - "How did this experience resonate with your emotional state?"

        Reply with ONLY the question.
        """
    }
}

enum GeminiError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case noContent

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        case .noContent:
            return "No content in response"
        }
    }
}

struct GeminiResponse: Codable {
    let candidates: [Candidate]?

    struct Candidate: Codable {
        let content: Content?
    }

    struct Content: Codable {
        let parts: [Part]?
    }

    struct Part: Codable {
        let text: String?
    }
}
