import SwiftUI

struct HomeView: View {
    @AppStorage("userName") private var userName = ""

    @State private var selectedMood: Mood?
    @State private var selectedActivities: Set<Activity> = []
    @State private var showPromptView = false
    @State private var showPromptPicker = false
    @State private var selectedPrompt: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    greetingSection

                    moodSection

                    if selectedMood != nil {
                        activitiesSection
                    }

                    if selectedMood != nil && !selectedActivities.isEmpty {
                        actionButtons
                    }
                }
                .padding()
            }
            .navigationTitle("Bookend")
            .fullScreenCover(isPresented: $showPromptView) {
                if let prompt = selectedPrompt {
                    PromptView(
                        mood: selectedMood ?? .okay,
                        activities: Array(selectedActivities),
                        preselectedPrompt: prompt
                    )
                } else {
                    PromptView(
                        mood: selectedMood ?? .okay,
                        activities: Array(selectedActivities)
                    )
                }
            }
            .sheet(isPresented: $showPromptPicker) {
                PromptPickerView(mood: selectedMood, activities: Array(selectedActivities)) { prompt in
                    selectedPrompt = prompt
                    showPromptPicker = false
                    showPromptView = true
                }
            }
            .onChange(of: showPromptView) { _, isShowing in
                if !isShowing {
                    selectedPrompt = nil
                }
            }
        }
    }

    private var greetingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(TimeOfDay.current.greeting), \(userName)")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("How are you feeling?")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var moodSection: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(Mood.allCases) { mood in
                MoodSelectCard(
                    mood: mood,
                    isSelected: selectedMood == mood
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        if selectedMood == mood {
                            selectedMood = nil
                            selectedActivities.removeAll()
                        } else {
                            selectedMood = mood
                        }
                    }
                }
            }
        }
    }

    private var activitiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What have you been up to?")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(Activity.allCases) { activity in
                    ActivitySelectCard(
                        activity: activity,
                        isSelected: selectedActivities.contains(activity)
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            if selectedActivities.contains(activity) {
                                selectedActivities.remove(activity)
                            } else {
                                selectedActivities.insert(activity)
                            }
                        }
                    }
                }
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                selectedPrompt = nil
                showPromptView = true
            } label: {
                HStack {
                    Image(systemName: "sparkles")
                    Text("Generate Prompt")
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
                showPromptPicker = true
            } label: {
                HStack {
                    Image(systemName: "text.quote")
                    Text("Pick from Library")
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.warmAccent)
            }
        }
        .padding(.top, 8)
    }
}

// MARK: - Mood Card

struct MoodSelectCard: View {
    let mood: Mood
    let isSelected: Bool
    let action: () -> Void

    private var cardColor: Color {
        switch mood {
        case .great, .good: return .green
        case .okay: return .blue
        case .low, .anxious, .stressed: return .purple
        case .calm: return .cyan
        case .energetic: return .orange
        case .tired: return .indigo
        case .grateful: return .pink
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(mood.emoji)
                    .font(.largeTitle)

                Text(mood.rawValue)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSelected ? cardColor : cardColor.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(isSelected ? cardColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Activity Card

struct ActivitySelectCard: View {
    let activity: Activity
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: activity.icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? .white : Color.warmAccent)

                Text(activity.rawValue)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(isSelected ? .white : .primary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(isSelected ? Color.warmAccent : Color.warmCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HomeView()
}
