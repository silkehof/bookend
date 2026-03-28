import SwiftUI

struct PromptView: View {
    let mood: Mood
    let activities: [Activity]
    var preselectedPrompt: String? = nil

    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @State private var prompt: String = ""
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showJournalEntry = false
    @State private var showPaperConfirmation = false
    @State private var showSavedConfirmation = false

    @AppStorage("geminiAPIKey") private var apiKey = ""
    @EnvironmentObject private var customPromptsManager: CustomPromptsManager
    @EnvironmentObject private var streakManager: StreakManager

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if isLoading {
                    loadingView
                } else if let error = errorMessage {
                    errorView(error)
                } else {
                    promptContentView
                }
            }
            .padding()
            .navigationTitle("Your Prompt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.title2)
                    }
                }
            }
            .task {
                await generatePrompt()
            }
            .fullScreenCover(isPresented: $showJournalEntry) {
                JournalEntryView(prompt: prompt, mood: mood, activities: activities)
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(Color.warmAccent)

            Text("Crafting your personalized prompt...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(_ error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.orange)

            Text("Unable to generate prompt")
                .font(.headline)

            Text(error)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Try Again") {
                Task {
                    await generatePrompt()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.warmAccent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var promptContentView: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 20) {
                Image(systemName: "sparkles")
                    .font(.system(size: 40))
                    .foregroundStyle(Color.warmAccent)

                Text("Today's Prompt")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(prompt)
                    .font(.title3)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(Color.warmCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20))

            contextSummary

            HStack(spacing: 24) {
                Button {
                    Task {
                        await generatePrompt()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.trianglehead.2.clockwise")
                        Text("New prompt")
                    }
                    .font(.subheadline)
                    .foregroundStyle(Color.warmAccent)
                }

                if preselectedPrompt == nil {
                    Button {
                        customPromptsManager.addPrompt(prompt, mood: mood, activity: activities.first)
                        showSavedConfirmation = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "heart")
                            Text("Save")
                        }
                        .font(.subheadline)
                        .foregroundStyle(Color.warmAccent)
                    }
                }
            }

            Spacer()

            VStack(spacing: 12) {
                Button {
                    showJournalEntry = true
                } label: {
                    HStack {
                        Image(systemName: "pencil.line")
                        Text("Start Writing")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.warmGradientStart, .warmGradientEnd],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                Button {
                    streakManager.logJournalEntry()
                    showPaperConfirmation = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "book.closed")
                        Text("I'll journal on paper")
                    }
                    .font(.subheadline)
                    .foregroundStyle(Color.warmAccent)
                }
            }
        }
        .alert("Logged!", isPresented: $showPaperConfirmation) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your journaling streak has been updated.")
        }
        .alert("Saved!", isPresented: $showSavedConfirmation) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("This prompt has been added to your library.")
        }
    }

    private var contextSummary: some View {
        HStack(spacing: 12) {
            Text(mood.emoji)
                .font(.title2)

            Text(activities.map { $0.rawValue }.joined(separator: " · "))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.warmCardBackground.opacity(0.6))
        .clipShape(Capsule())
    }

    private func generatePrompt() async {
        // If we have a preselected prompt, use it
        if let preselected = preselectedPrompt, prompt.isEmpty {
            prompt = preselected
            isLoading = false
            return
        }

        isLoading = true
        errorMessage = nil

        // 30% chance to use a custom prompt if available and matching
        if customPromptsManager.hasMatchingPrompts(mood: mood, activity: activities.first) && Int.random(in: 1...10) <= 3 {
            if let customPrompt = customPromptsManager.getRandomPrompt(for: mood, activity: activities.first) {
                prompt = customPrompt
                isLoading = false
                return
            }
        }

        // Try online first if API key exists
        if !apiKey.isEmpty {
            let service = GeminiService(apiKey: apiKey)
            do {
                prompt = try await service.generatePrompt(
                    mood: mood,
                    activities: activities,
                    timeOfDay: TimeOfDay.current
                )
                isLoading = false
                return
            } catch {
                // Fall through to offline prompts
            }
        }

        // Use offline prompts as fallback
        prompt = OfflinePrompts.getPrompt(mood: mood, activities: activities, timeOfDay: TimeOfDay.current)
        isLoading = false
    }
}

#Preview {
    PromptView(mood: .good, activities: [.work, .exercise])
}
