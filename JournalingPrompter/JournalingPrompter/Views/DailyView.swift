import SwiftUI
import EventKit

struct DailyView: View {
    @AppStorage("userName") private var userName = ""
    @StateObject private var entryManager = DailyEntryManager.shared
    @State private var todayEntry: DailyEntry?
    @State private var newPriorityText = ""
    @State private var morningThoughts = ""
    @State private var eveningReflection = ""
    @State private var showRolloverSheet = false
    @State private var incompletePriorities: [Priority] = []
    @State private var showPromptPicker = false
    @State private var currentPrompt: String?
    @State private var hasCheckedRollover = false
    @State private var selectedMorningMood: Mood?
    @State private var selectedEveningMood: Mood?
    @State private var selectedActivities: Set<Activity> = []
    @State private var showSavedIndicator = false
    @State private var journaledOnPaper = false
    @State private var showCelebration = false

    // 0 = auto, 1 = morning, 2 = evening
    @AppStorage("devTimeOfDayOverride") private var devTimeOverride = 0

    private var timeOfDay: TimeOfDay {
        switch devTimeOverride {
        case 1: return .morning
        case 2: return .evening
        default: return TimeOfDay.current
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    greetingSection

                    if timeOfDay.isMorningMode {
                        morningContent
                    } else {
                        eveningContent
                    }
                }
                .padding()
            }
            .scrollDismissesKeyboard(.immediately)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Picker("Time", selection: $devTimeOverride) {
                        Text("Auto").tag(0)
                        Text("Morning").tag(1)
                        Text("Evening").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 220)
                }
            }
            .onAppear {
                loadTodayEntry()
                checkForRollover()
                if timeOfDay.isMorningMode {
                    CalendarService.shared.fetchTodayEvents()
                }
            }
            .sheet(isPresented: $showRolloverSheet) {
                RolloverSheet(
                    priorities: incompletePriorities,
                    onRollover: { selected in
                        rollOverSelected(selected)
                    }
                )
            }
            .sheet(isPresented: $showPromptPicker) {
                PromptSelectionSheet(
                    mood: selectedEveningMood,
                    activities: Array(selectedActivities),
                    onSelect: { prompt in
                        currentPrompt = prompt
                        if let entry = todayEntry {
                            entryManager.updateReflectionPrompt(prompt, for: entry)
                        }
                        showPromptPicker = false
                    }
                )
            }
        }
    }

    private func showSaved() {
        withAnimation(.easeIn(duration: 0.2)) {
            showSavedIndicator = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut(duration: 0.3)) {
                showSavedIndicator = false
            }
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d. MMMM"
        return formatter.string(from: Date())
    }

    // MARK: - Greeting

    private var greetingSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(timeOfDay.greeting), \(userName)!")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text(formattedDate)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if showSavedIndicator {
                Text("Saved")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .transition(.opacity)
                    .padding(.top, 12)
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Morning Content

    private var morningContent: some View {
        VStack(spacing: 24) {
            calendarEventsSection
            prioritiesSection
            moodSection(title: "How are you feeling this morning?", selectedMood: $selectedMorningMood, isMorning: true)
            morningThoughtsSection
        }
    }

    @ViewBuilder
    private var calendarEventsSection: some View {
        let calendarService = CalendarService.shared
        if calendarService.calendarEnabled &&
           calendarService.authorizationStatus == .fullAccess &&
           !calendarService.todayEvents.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .foregroundStyle(Color.warmAccent)
                    Text("Today's Events")
                        .font(.title3)
                        .fontWeight(.semibold)
                }

                ForEach(calendarService.todayEvents, id: \.eventIdentifier) { event in
                    HStack(spacing: 10) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(cgColor: event.calendar.cgColor))
                            .frame(width: 4, height: 36)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(event.title)
                                .font(.subheadline)
                            Text(formattedEventTime(event))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }
            }
            .padding(16)
            .background(Color.warmSecondary.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.warmAccent.opacity(0.25), lineWidth: 1.5)
            }
        }
    }

    private func formattedEventTime(_ event: EKEvent) -> String {
        if event.isAllDay {
            return "All day"
        }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        let start = formatter.string(from: event.startDate)
        let end = formatter.string(from: event.endDate)
        return "\(start) – \(end)"
    }

    private func moodSection(title: String, selectedMood: Binding<Mood?>, isMorning: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(Mood.allCases) { mood in
                    MoodButton(
                        mood: mood,
                        isSelected: selectedMood.wrappedValue == mood
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            if selectedMood.wrappedValue == mood {
                                selectedMood.wrappedValue = nil
                            } else {
                                selectedMood.wrappedValue = mood
                            }
                            saveMood(mood: selectedMood.wrappedValue, isMorning: isMorning)
                        }
                    }
                }
            }
        }
    }

    private var prioritiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today's Priorities")
                    .font(.title3)
                    .fontWeight(.semibold)

                Spacer()

                if let entry = todayEntry, entry.totalCount > 0 {
                    Text("\(entry.completedCount)/\(entry.totalCount)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            if timeOfDay.isMorningMode {
                HStack {
                    TextField("What matters most today?", text: $newPriorityText)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(Color.warmCardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .onSubmit {
                            addPriority()
                        }

                    Button(action: addPriority) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Color.warmAccent)
                    }
                    .disabled(newPriorityText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }

            if let entry = todayEntry, !entry.prioritiesArray.isEmpty {
                ForEach(entry.prioritiesArray) { priority in
                    PriorityRow(
                        priority: priority,
                        onToggle: {
                            entryManager.togglePriority(priority)
                            todayEntry = entryManager.getTodayEntry()
                        },
                        onDelete: {
                            entryManager.deletePriority(priority)
                            todayEntry = entryManager.getTodayEntry()
                            showSaved()
                        },
                        onEdit: { newText in
                            entryManager.updatePriorityText(priority, text: newText)
                            todayEntry = entryManager.getTodayEntry()
                            showSaved()
                        }
                    )
                }
            } else if timeOfDay.isEveningMode {
                Text("No priorities set for today")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            }

        }
        .padding(16)
        .background(Color.warmSecondary.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.warmAccent.opacity(0.25), lineWidth: 1.5)
        }
    }

    private var morningThoughtsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Morning Thoughts")
                .font(.headline)

            TextEditor(text: $morningThoughts)
                .frame(minHeight: 120)
                .scrollContentBackground(.hidden)
                .padding(12)
                .background(Color.warmCardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .onChange(of: morningThoughts) { _, newValue in
                    if let entry = todayEntry {
                        entryManager.updateMorningThoughts(newValue, for: entry)
                        showSaved()
                    }
                }

            Text("What's on your mind as you start the day?")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }

    // MARK: - Evening Content

    private var eveningContent: some View {
        VStack(spacing: 24) {
            prioritiesSection
            moodSection(title: "How are you feeling tonight?", selectedMood: $selectedEveningMood, isMorning: false)
            activitiesSection
            eveningReflectionSection
            finishDaySection
        }
    }

    private var activitiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What shaped your day?")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(Activity.allCases) { activity in
                    ActivityButton(
                        activity: activity,
                        isSelected: selectedActivities.contains(activity)
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            if selectedActivities.contains(activity) {
                                selectedActivities.remove(activity)
                            } else {
                                selectedActivities.insert(activity)
                            }
                            saveActivities()
                        }
                    }
                }
            }
        }
    }


    private var eveningReflectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Evening Reflection")
                    .font(.headline)

                Spacer()

                if !journaledOnPaper {
                    Button {
                        showPromptPicker = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                            Text((currentPrompt ?? todayEntry?.reflectionPrompt) != nil ? "Change Prompt" : "Get Prompt")
                        }
                        .font(.subheadline)
                        .foregroundStyle(Color.warmAccent)
                    }
                }
            }

            if !journaledOnPaper {
                if let prompt = currentPrompt ?? todayEntry?.reflectionPrompt {
                    Text(prompt)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.warmAccent.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                ZStack(alignment: .topLeading) {
                    if eveningReflection.isEmpty {
                        Text("How did your day go? What did you learn?")
                            .font(.body)
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 20)
                            .allowsHitTesting(false)
                    }
                    TextEditor(text: $eveningReflection)
                        .frame(minHeight: 150)
                        .scrollContentBackground(.hidden)
                        .padding(12)
                        .onChange(of: eveningReflection) { _, newValue in
                            if let entry = todayEntry {
                                entryManager.updateEveningReflection(newValue, for: entry)
                                showSaved()
                            }
                        }
                }
                .background(Color.warmCardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            if journaledOnPaper || eveningReflection.isEmpty {
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        journaledOnPaper.toggle()
                        if let entry = todayEntry {
                            entryManager.updatePaperJournalStatus(journaledOnPaper, for: entry)
                            showSaved()
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: journaledOnPaper ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(journaledOnPaper ? Color.warmAccent : Color.secondary)
                        Text("Journaled on paper today")
                            .font(.subheadline)
                            .foregroundStyle(journaledOnPaper ? Color.warmAccent : Color.secondary)
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var finishDaySection: some View {
        VStack(spacing: 12) {
            if let entry = todayEntry {
                if entry.isCompleted {
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            showCelebration = true
                        }

                        // Auto-hide celebration after 2 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation(.easeOut(duration: 0.3)) {
                                showCelebration = false
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: showCelebration ? "checkmark.circle.fill" : "moon.stars.fill")
                                .font(.title3)

                            Text(showCelebration ? "Day Complete! 🎉" : "Finish Day")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: showCelebration ? [.green, .green] : [Color(red: 0.95, green: 0.65, blue: 0.50), Color(red: 0.85, green: 0.50, blue: 0.55)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .disabled(showCelebration)
                } else {
                    // Show what's missing for completion
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.secondary)
                        Text(incompletenessReason)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color.warmCardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }

    private var incompletenessReason: String {
        guard let entry = todayEntry else { return "Loading..." }

        let hasReflection = !(entry.eveningReflection ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        if !hasReflection && !entry.journaledOnPaper {
            return "Write an evening reflection or mark as journaled on paper"
        }

        return "Continue filling out your day"
    }

    // MARK: - Actions

    private func loadTodayEntry() {
        todayEntry = entryManager.getOrCreateTodayEntry()
        morningThoughts = todayEntry?.morningThoughts ?? ""
        eveningReflection = todayEntry?.eveningReflection ?? ""
        currentPrompt = todayEntry?.reflectionPrompt
        journaledOnPaper = todayEntry?.journaledOnPaper ?? false

        // Load saved moods
        if let morningMoodString = todayEntry?.morningMood {
            selectedMorningMood = Mood(rawValue: morningMoodString)
        }
        if let eveningMoodString = todayEntry?.eveningMood {
            selectedEveningMood = Mood(rawValue: eveningMoodString)
        }

        // Load saved activities
        if let activitiesString = todayEntry?.eveningActivities {
            let activityNames = activitiesString.split(separator: ",").map { String($0) }
            selectedActivities = Set(activityNames.compactMap { Activity(rawValue: $0) })
        }
    }

    private func addPriority() {
        let text = newPriorityText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty, let entry = todayEntry else { return }
        entryManager.addPriority(text: text, to: entry)
        newPriorityText = ""
        todayEntry = entryManager.getTodayEntry()
        showSaved()
    }

    private func checkForRollover() {
        guard !hasCheckedRollover && timeOfDay.isMorningMode else { return }
        hasCheckedRollover = true

        let incomplete = entryManager.getIncompletePrioritiesFromYesterday()
        if !incomplete.isEmpty {
            incompletePriorities = incomplete
            showRolloverSheet = true
        }
    }

    private func rollOverSelected(_ priorities: [Priority]) {
        guard let entry = todayEntry else { return }
        for priority in priorities {
            entryManager.rollOverPriority(priority, to: entry)
        }
        todayEntry = entryManager.getTodayEntry()
    }

    private func saveMood(mood: Mood?, isMorning: Bool) {
        guard let entry = todayEntry else { return }
        if isMorning {
            entryManager.updateMorningMood(mood?.rawValue, for: entry)
        } else {
            entryManager.updateEveningMood(mood?.rawValue, for: entry)
        }
        showSaved()
    }

    private func saveActivities() {
        guard let entry = todayEntry else { return }
        let activitiesString = selectedActivities.map { $0.rawValue }.joined(separator: ",")
        entryManager.updateEveningActivities(activitiesString, for: entry)
        showSaved()
    }
}

// MARK: - Mood Button

struct MoodButton: View {
    let mood: Mood
    let isSelected: Bool
    let action: () -> Void

    private var moodColor: Color {
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
            VStack(spacing: 6) {
                Text(mood.emoji)
                    .font(.title2)

                Text(mood.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? moodColor : moodColor.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Activity Button

struct ActivityButton: View {
    let activity: Activity
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: activity.icon)
                    .font(.title3)
                    .foregroundStyle(isSelected ? .white : Color.warmAccent)

                Text(activity.rawValue)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(isSelected ? .white : .primary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected ? Color.warmAccent : Color.warmCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Priority Row

struct PriorityRow: View {
    let priority: Priority
    let onToggle: () -> Void
    let onDelete: () -> Void
    let onEdit: (String) -> Void

    @State private var isEditing = false
    @State private var editText = ""
    @FocusState private var isEditFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            Button {
                onToggle()
            } label: {
                Image(systemName: priority.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(priority.isCompleted ? Color.green : Color.secondary)
            }
            .buttonStyle(.borderless)

            if isEditing {
                TextField("Priority", text: $editText)
                    .textFieldStyle(.plain)
                    .focused($isEditFocused)
                    .onSubmit { saveEdit() }
                    .onAppear { isEditFocused = true }
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    Text(priority.text ?? "")
                        .strikethrough(priority.isCompleted)
                        .foregroundStyle(priority.isCompleted ? .secondary : .primary)

                    if priority.wasRolledOver {
                        Text("Rolled over")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    editText = priority.text ?? ""
                    isEditing = true
                }
            }

            Spacer()

            if isEditing {
                Button { saveEdit() } label: {
                    Image(systemName: "checkmark")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.warmAccent)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(12)
        .background(Color.warmCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .contextMenu {
            Button {
                editText = priority.text ?? ""
                isEditing = true
            } label: {
                Label("Edit", systemImage: "pencil")
            }

            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func saveEdit() {
        let trimmed = editText.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            onEdit(trimmed)
        }
        isEditing = false
    }
}

// MARK: - Rollover Sheet

struct RolloverSheet: View {
    let priorities: [Priority]
    let onRollover: ([Priority]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedPriorities: Set<UUID> = []

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("You had incomplete priorities from yesterday. Would you like to carry any forward?")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                List {
                    ForEach(priorities) { priority in
                        HStack {
                            Image(systemName: selectedPriorities.contains(priority.id ?? UUID()) ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(selectedPriorities.contains(priority.id ?? UUID()) ? Color.warmAccent : Color.secondary)

                            Text(priority.text ?? "")
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if let id = priority.id {
                                if selectedPriorities.contains(id) {
                                    selectedPriorities.remove(id)
                                } else {
                                    selectedPriorities.insert(id)
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)

                HStack(spacing: 16) {
                    Button("Skip All") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)

                    Button("Roll Over Selected") {
                        let selected = priorities.filter { selectedPriorities.contains($0.id ?? UUID()) }
                        onRollover(selected)
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.warmAccent)
                    .disabled(selectedPriorities.isEmpty)
                }
                .padding()
            }
            .navigationTitle("Yesterday's Priorities")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Prompt Selection Sheet

struct PromptSelectionSheet: View {
    let mood: Mood?
    let activities: [Activity]
    let onSelect: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var isGenerating = false
    @State private var generatedPrompt: String?

    var body: some View {
        NavigationStack {
            List {
                Section("AI Generated") {
                    Button {
                        generatePrompt()
                    } label: {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundStyle(Color.warmAccent)
                            Text("Generate with AI")

                            Spacer()

                            if isGenerating {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isGenerating)

                    if let prompt = generatedPrompt {
                        Text(prompt)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .onTapGesture {
                                onSelect(prompt)
                            }
                    }
                }

                Section("From Library") {
                    ForEach(OfflinePrompts.eveningReflection, id: \.self) { prompt in
                        Text(prompt)
                            .font(.subheadline)
                            .onTapGesture {
                                onSelect(prompt)
                            }
                    }
                }
            }
            .navigationTitle("Choose a Prompt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func generatePrompt() {
        isGenerating = true
        Task {
            do {
                let prompt: String
                if let mood = mood {
                    prompt = try await GeminiService.shared.generatePrompt(
                        mood: mood,
                        activities: activities,
                        timeOfDay: .current
                    )
                } else {
                    prompt = try await GeminiService.shared.generateReflectionPrompt()
                }
                await MainActor.run {
                    generatedPrompt = prompt
                    isGenerating = false
                }
            } catch {
                await MainActor.run {
                    // Fallback to context-aware offline prompt or random
                    if let mood = mood {
                        generatedPrompt = OfflinePrompts.getPrompt(mood: mood, activities: activities, timeOfDay: .current)
                    } else {
                        generatedPrompt = OfflinePrompts.eveningReflection.randomElement()
                    }
                    isGenerating = false
                }
            }
        }
    }
}

#Preview {
    DailyView()
}
