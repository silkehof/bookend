import SwiftUI

struct JournalEntryView: View {
    let prompt: String
    let mood: Mood
    let activities: [Activity]

    @Environment(\.dismiss) private var dismiss

    @State private var entryText = ""
    @State private var showingSaveConfirmation = false
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                promptHeader

                Divider()

                textEditor

                Divider()

                bottomBar
            }
            .navigationTitle("Write")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(Color.warmAccent)
                }

                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        saveEntry()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.warmAccent)
                    .disabled(entryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert("Entry Saved", isPresented: $showingSaveConfirmation) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your journal entry has been saved successfully.")
            }
            .onAppear {
                isTextFieldFocused = true
            }
        }
    }

    private var promptHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Today's Prompt", systemImage: "sparkles")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(prompt)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.warmCardBackground)
    }

    private var textEditor: some View {
        TextEditor(text: $entryText)
            .focused($isTextFieldFocused)
            .scrollContentBackground(.hidden)
            .padding()
            .overlay(alignment: .topLeading) {
                if entryText.isEmpty {
                    Text("Start writing your thoughts...")
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 28)
                        .allowsHitTesting(false)
                }
            }
    }

    private var bottomBar: some View {
        HStack {
            Text("\(wordCount) words")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            HStack(spacing: 4) {
                Text(mood.emoji)
                ForEach(activities.prefix(3)) { activity in
                    Image(systemName: activity.icon)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if activities.count > 3 {
                    Text("+\(activities.count - 3)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
    }

    private var wordCount: Int {
        entryText.split(separator: " ").count
    }

    private func saveEntry() {
        let trimmedText = entryText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        let entryManager = DailyEntryManager.shared
        let dailyEntry = entryManager.getOrCreateTodayEntry()
        entryManager.updateEveningReflection(trimmedText, for: dailyEntry)
        entryManager.updateEveningMood(mood.rawValue, for: dailyEntry)
        entryManager.updateEveningActivities(activities.map { $0.rawValue }.joined(separator: ","), for: dailyEntry)
        entryManager.updateReflectionPrompt(prompt, for: dailyEntry)

        showingSaveConfirmation = true
    }
}

#Preview {
    NavigationStack {
        JournalEntryView(
            prompt: "What's one small thing that brought you joy today?",
            mood: .good,
            activities: [.work, .exercise, .socializing]
        )
    }
}
