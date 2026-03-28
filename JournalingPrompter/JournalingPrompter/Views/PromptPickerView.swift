import SwiftUI

struct PromptPickerView: View {
    let mood: Mood?
    let activities: [Activity]
    let onSelect: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var customPromptsManager: CustomPromptsManager

    @State private var selectedTab = 0

    private var myPrompts: [String] {
        customPromptsManager.prompts
            .filter { $0.matches(mood: mood, activity: activities.first) }
            .map { $0.text }
    }

    private var suggestedPrompts: [String] {
        var prompts: [String] = []

        // Get mood-specific prompts
        if let mood = mood {
            prompts.append(contentsOf: OfflinePrompts.getMoodPrompts(for: mood).prefix(8))
        }

        // Get activity-specific prompts
        if let activity = activities.first {
            prompts.append(contentsOf: OfflinePrompts.getActivityPrompts(for: activity).prefix(5))
        }

        return Array(Set(prompts)).shuffled()
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab picker
                if !myPrompts.isEmpty {
                    Picker("Source", selection: $selectedTab) {
                        Text("My Prompts").tag(0)
                        Text("Suggested").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding()
                }

                ScrollView {
                    VStack(spacing: 12) {
                        if selectedTab == 0 && !myPrompts.isEmpty {
                            ForEach(myPrompts, id: \.self) { prompt in
                                PromptPickerCard(prompt: prompt) {
                                    onSelect(prompt)
                                }
                            }
                        } else {
                            ForEach(suggestedPrompts, id: \.self) { prompt in
                                PromptPickerCard(prompt: prompt) {
                                    onSelect(prompt)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Pick a Prompt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Default to suggested if no custom prompts match
                if myPrompts.isEmpty {
                    selectedTab = 1
                }
            }
        }
    }
}

struct PromptPickerCard: View {
    let prompt: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "quote.opening")
                    .font(.caption)
                    .foregroundStyle(Color.warmAccent)

                Text(prompt)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(Color.warmCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PromptPickerView(mood: .good, activities: [.work]) { _ in }
        .environmentObject(CustomPromptsManager())
}
