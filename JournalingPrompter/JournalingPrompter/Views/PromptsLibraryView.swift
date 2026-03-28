import SwiftUI

struct PromptsLibraryView: View {
    @EnvironmentObject private var customPromptsManager: CustomPromptsManager
    @State private var selectedTab = 0
    @State private var showingAddPrompt = false
    @State private var randomPrompt: String?
    @State private var showRandomPrompt = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Inspiration card
                    inspirationCard

                    // Tab selector
                    tabSelector

                    // Content based on selected tab
                    if selectedTab == 0 {
                        myPromptsContent
                    } else {
                        builtInContent
                    }
                }
                .padding()
            }
            .navigationTitle("Prompts")
            .toolbar {
                if selectedTab == 0 {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            showingAddPrompt = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundStyle(Color.warmAccent)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddPrompt) {
                AddPromptView()
            }
            .sheet(isPresented: $showRandomPrompt) {
                RandomPromptView(prompt: randomPrompt ?? "")
            }
        }
    }

    private var inspirationCard: some View {
        Button {
            randomPrompt = OfflinePrompts.getRandomPrompt()
            showRandomPrompt = true
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.warmGradientStart, .warmGradientEnd],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)

                    Image(systemName: "sparkles")
                        .font(.title2)
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Need inspiration?")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text("Tap for a random prompt")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.warmAccent.opacity(0.6))
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.warmCardBackground, Color.warmCardBackground.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private var tabSelector: some View {
        HStack(spacing: 12) {
            TabButton(
                title: "My Prompts",
                icon: "heart.fill",
                isSelected: selectedTab == 0,
                color: .pink
            ) {
                withAnimation(.spring(response: 0.3)) {
                    selectedTab = 0
                }
            }

            TabButton(
                title: "Discover",
                icon: "safari",
                isSelected: selectedTab == 1,
                color: .orange
            ) {
                withAnimation(.spring(response: 0.3)) {
                    selectedTab = 1
                }
            }
        }
    }

    @ViewBuilder
    private var myPromptsContent: some View {
        if customPromptsManager.prompts.isEmpty {
            emptyMyPromptsView
        } else {
            VStack(spacing: 12) {
                ForEach(customPromptsManager.prompts) { prompt in
                    CustomPromptCard(prompt: prompt) {
                        if let index = customPromptsManager.prompts.firstIndex(where: { $0.id == prompt.id }) {
                            withAnimation {
                                customPromptsManager.removePrompt(at: index)
                            }
                        }
                    }
                }
            }
        }
    }

    private var emptyMyPromptsView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.warmCardBackground)
                    .frame(width: 100, height: 100)

                Image(systemName: "heart.text.square")
                    .font(.system(size: 40))
                    .foregroundStyle(Color.warmAccent)
            }

            VStack(spacing: 8) {
                Text("Your collection is empty")
                    .font(.headline)

                Text("Create prompts that resonate with you.\nThey'll appear when you journal.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                showingAddPrompt = true
            } label: {
                HStack {
                    Image(systemName: "plus")
                    Text("Create Your First Prompt")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [.warmGradientStart, .warmGradientEnd],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
            }
        }
        .padding(.vertical, 40)
    }

    private var builtInContent: some View {
        VStack(spacing: 20) {
            // Moods section
            VStack(alignment: .leading, spacing: 12) {
                Text("By Mood")
                    .font(.headline)
                    .padding(.horizontal, 4)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(Mood.allCases) { mood in
                        NavigationLink {
                            MoodPromptsListView(mood: mood)
                        } label: {
                            MoodCard(mood: mood)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Activities section
            VStack(alignment: .leading, spacing: 12) {
                Text("By Activity")
                    .font(.headline)
                    .padding(.horizontal, 4)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(Activity.allCases) { activity in
                        NavigationLink {
                            ActivityPromptsListView(activity: activity)
                        } label: {
                            ActivityCard(activity: activity)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline)
                Text(title)
                    .font(.subheadline.weight(.medium))
            }
            .foregroundStyle(isSelected ? .white : .secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? color : Color.warmCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

struct MoodCard: View {
    let mood: Mood

    private var cardColor: Color {
        switch mood {
        case .great, .good: return .green.opacity(0.15)
        case .okay: return .blue.opacity(0.15)
        case .low, .anxious, .stressed: return .purple.opacity(0.15)
        case .calm: return .cyan.opacity(0.15)
        case .energetic: return .orange.opacity(0.15)
        case .tired: return .indigo.opacity(0.15)
        case .grateful: return .pink.opacity(0.15)
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            Text(mood.emoji)
                .font(.largeTitle)

            Text(mood.rawValue)
                .font(.caption.weight(.medium))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(cardColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct ActivityCard: View {
    let activity: Activity

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: activity.icon)
                .font(.title2)
                .foregroundStyle(Color.warmAccent)

            Text(activity.rawValue)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.warmCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct CustomPromptCard: View {
    let prompt: CustomPrompt
    let onDelete: () -> Void

    @State private var showDeleteConfirm = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Image(systemName: "quote.opening")
                    .font(.caption)
                    .foregroundStyle(Color.warmAccent)

                Spacer()

                Menu {
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(.secondary)
                }
            }

            Text(prompt.text)
                .font(.subheadline)
                .foregroundStyle(.primary)

            if prompt.moodEnum != nil || prompt.activityEnum != nil {
                HStack(spacing: 8) {
                    if let mood = prompt.moodEnum {
                        HStack(spacing: 4) {
                            Text(mood.emoji)
                            Text(mood.rawValue)
                        }
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.warmAccent.opacity(0.15))
                        .clipShape(Capsule())
                    }

                    if let activity = prompt.activityEnum {
                        HStack(spacing: 4) {
                            Image(systemName: activity.icon)
                                .font(.caption2)
                            Text(activity.rawValue)
                        }
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.warmAccent.opacity(0.15))
                        .clipShape(Capsule())
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.warmCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .confirmationDialog("Delete this prompt?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive, action: onDelete)
            Button("Cancel", role: .cancel) { }
        }
    }
}

struct RandomPromptView: View {
    let prompt: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.warmGradientStart.opacity(0.3), .warmGradientEnd.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)

                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 35))
                        .foregroundStyle(Color.warmAccent)
                }

                Text("Here's an idea...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(prompt)
                    .font(.title3.weight(.medium))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(32)
            .background(Color.warmCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .padding(.horizontal)

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("Got it!")
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
            .padding(.horizontal)
            .padding(.bottom)
        }
        .background(Color(.systemBackground))
    }
}

struct AddPromptView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var customPromptsManager: CustomPromptsManager

    @State private var promptText = ""
    @State private var selectedMood: Mood?
    @State private var selectedActivity: Activity?
    @FocusState private var isTextFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Prompt input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Prompt")
                            .font(.headline)

                        TextField("What question inspires your reflection?", text: $promptText, axis: .vertical)
                            .lineLimit(3...6)
                            .focused($isTextFocused)
                            .padding()
                            .background(Color.warmCardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // Optional filters
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Show when (optional)")
                            .font(.headline)

                        Text("Pick a mood or activity to show this prompt only when you select it.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        // Mood picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Mood")
                                .font(.subheadline.weight(.medium))

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    FilterChip(title: "Any", isSelected: selectedMood == nil) {
                                        selectedMood = nil
                                    }

                                    ForEach(Mood.allCases) { mood in
                                        FilterChip(
                                            title: "\(mood.emoji) \(mood.rawValue)",
                                            isSelected: selectedMood == mood
                                        ) {
                                            selectedMood = mood
                                        }
                                    }
                                }
                            }
                        }

                        // Activity picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Activity")
                                .font(.subheadline.weight(.medium))

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    FilterChip(title: "Any", isSelected: selectedActivity == nil) {
                                        selectedActivity = nil
                                    }

                                    ForEach(Activity.allCases) { activity in
                                        FilterChip(
                                            title: activity.rawValue,
                                            isSelected: selectedActivity == activity
                                        ) {
                                            selectedActivity = activity
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Spacer(minLength: 40)

                    // Save button
                    Button {
                        customPromptsManager.addPrompt(promptText, mood: selectedMood, activity: selectedActivity)
                        dismiss()
                    } label: {
                        Text("Save Prompt")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: promptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                        ? [.gray, .gray]
                                        : [.warmGradientStart, .warmGradientEnd],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(promptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding()
            }
            .navigationTitle("New Prompt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                isTextFocused = true
            }
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? Color.warmAccent : Color.warmCardBackground)
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct MoodPromptsListView: View {
    let mood: Mood

    private var prompts: [String] {
        OfflinePrompts.getMoodPrompts(for: mood)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(prompts, id: \.self) { prompt in
                    PromptCard(prompt: prompt)
                }
            }
            .padding()
        }
        .navigationTitle("\(mood.emoji) \(mood.rawValue)")
        .background(Color(.systemGroupedBackground))
    }
}

struct ActivityPromptsListView: View {
    let activity: Activity

    private var prompts: [String] {
        OfflinePrompts.getActivityPrompts(for: activity)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(prompts, id: \.self) { prompt in
                    PromptCard(prompt: prompt)
                }
            }
            .padding()
        }
        .navigationTitle(activity.rawValue)
        .background(Color(.systemGroupedBackground))
    }
}

struct PromptCard: View {
    let prompt: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "quote.opening")
                .font(.caption)
                .foregroundStyle(Color.warmAccent)

            Text(prompt)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color.warmCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    PromptsLibraryView()
        .environmentObject(CustomPromptsManager())
}
