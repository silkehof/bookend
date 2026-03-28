import Foundation
import SwiftUI

@MainActor
class CustomPromptsManager: ObservableObject {
    @Published var prompts: [CustomPrompt] = []

    private let storageKey = "customPromptsV2"

    init() {
        loadPrompts()
    }

    private func loadPrompts() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([CustomPrompt].self, from: data) {
            prompts = decoded
        }
    }

    private func savePrompts() {
        if let encoded = try? JSONEncoder().encode(prompts) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }

    func addPrompt(_ text: String, mood: Mood? = nil, activity: Activity? = nil) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let prompt = CustomPrompt(text: trimmed, mood: mood, activity: activity)
        prompts.append(prompt)
        savePrompts()
    }

    func removePrompt(_ prompt: CustomPrompt) {
        prompts.removeAll { $0.id == prompt.id }
        savePrompts()
    }

    func removePrompt(at index: Int) {
        guard prompts.indices.contains(index) else { return }
        prompts.remove(at: index)
        savePrompts()
    }

    func getRandomPrompt(for mood: Mood? = nil, activity: Activity? = nil) -> String? {
        let matching = prompts.filter { $0.matches(mood: mood, activity: activity) }
        return matching.randomElement()?.text
    }

    var hasPrompts: Bool {
        !prompts.isEmpty
    }

    func hasMatchingPrompts(mood: Mood?, activity: Activity?) -> Bool {
        prompts.contains { $0.matches(mood: mood, activity: activity) }
    }
}
