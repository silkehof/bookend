import SwiftUI
import EventKit

// MARK: - Step Enums

enum MorningStep: Int {
    case mood = 0
    case priorities = 1
    case calendarEvents = 2
    case thoughts = 3
    case startDay = 4
}

enum EveningStep: Int {
    case priorities = 0
    case mood = 1
    case activities = 2
    case reflection = 3
    case finishDay = 4
}

// MARK: - Step Indicator

struct StepIndicatorView: View {
    let totalSteps: Int
    let currentStep: Int
    let onBack: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.warmAccent)
            }
            .opacity(currentStep == 0 ? 0 : 1)
            .disabled(currentStep == 0)

            HStack(spacing: 6) {
                ForEach(0..<totalSteps, id: \.self) { index in
                    Capsule()
                        .fill(index == currentStep ? Color.warmAccent : Color.warmSecondary.opacity(0.4))
                        .frame(width: index == currentStep ? 24 : 8, height: 8)
                        .animation(.spring(response: 0.3), value: currentStep)
                }
            }
            .frame(maxWidth: .infinity)

            // Mirror back button width for centering
            Image(systemName: "chevron.left")
                .font(.body.weight(.semibold))
                .opacity(0)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

// MARK: - Step Card

struct StepCard<Content: View>: View {
    let title: String
    let continueLabel: String
    let onContinue: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.bottom, 20)

            content()

            Spacer()

            Button(action: onContinue) {
                Text(continueLabel)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color.warmGradientStart, Color.warmGradientEnd],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .padding(.top, 16)
        }
        .padding()
    }
}

// MARK: - DailyView

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
    @AppStorage("lastFinishedDayDate") private var lastFinishedDayDate = ""
    @State private var showMorningStarted = false
    @AppStorage("lastStartedDayDate") private var lastStartedDayDate = ""
    @State private var isReordering = false
    @State private var currentStep: Int = 0
    @State private var goingForward: Bool = true
    @FocusState private var isThoughtsFocused: Bool
    @FocusState private var isReflectionFocused: Bool

    #if DEBUG
    @AppStorage("devTimeOfDayOverride") private var devTimeOverride = 0
    #endif

    private var timeOfDay: TimeOfDay {
        #if DEBUG
        switch devTimeOverride {
        case 1: return .morning
        case 2: return .evening
        default: return TimeOfDay.current
        }
        #else
        return TimeOfDay.current
        #endif
    }

    private var hasCalendarStep: Bool {
        let cal = CalendarService.shared
        return cal.calendarEnabled && cal.authorizationStatus == .fullAccess && !cal.todayEvents.isEmpty
    }

    private var morningStepCount: Int { hasCalendarStep ? 5 : 4 }
    private var eveningStepCount: Int { 5 }

    private var totalSteps: Int {
        timeOfDay.isMorningMode ? morningStepCount : eveningStepCount
    }

    // Map a linear index to MorningStep, skipping .calendarEvents when not available
    private func morningStep(at index: Int) -> MorningStep {
        if hasCalendarStep {
            return MorningStep(rawValue: index) ?? .mood
        } else {
            // 0→mood, 1→priorities, 2→thoughts, 3→startDay
            let raw = index < 2 ? index : index + 1
            return MorningStep(rawValue: raw) ?? .mood
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                greetingSection
                    .padding(.horizontal)
                    .padding(.top, 8)

                StepIndicatorView(
                    totalSteps: totalSteps,
                    currentStep: currentStep,
                    onBack: {
                        goingForward = false
                        withAnimation(.spring(response: 0.3)) {
                            currentStep -= 1
                        }
                    }
                )

                ZStack {
                    if timeOfDay.isMorningMode {
                        morningStepView(for: morningStep(at: currentStep))
                            .id("m\(currentStep)")
                            .transition(stepTransition)
                    } else {
                        eveningStepView(for: EveningStep(rawValue: currentStep) ?? .priorities)
                            .id("e\(currentStep)")
                            .transition(stepTransition)
                    }
                }
                .animation(.spring(response: 0.3), value: currentStep)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                #if DEBUG
                ToolbarItem(placement: .principal) {
                    Picker("Time", selection: $devTimeOverride) {
                        Text("Auto").tag(0)
                        Text("Morning").tag(1)
                        Text("Evening").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 220)
                }
                #endif
            }
            .onAppear {
                loadTodayEntry()
                checkForRollover()
                if timeOfDay.isMorningMode {
                    CalendarService.shared.fetchTodayEvents()
                    // Restore "started" state if already tapped today
                    if lastStartedDayDate == todayDateString {
                        showMorningStarted = true
                    }
                }
                if !timeOfDay.isMorningMode, let entry = todayEntry, entry.isCompleted {
                    currentStep = eveningStepCount - 1
                    if lastFinishedDayDate == todayDateString {
                        showCelebration = true
                    }
                }
            }
            .onChange(of: timeOfDay.isMorningMode) { _, _ in
                currentStep = 0
            }
            .sheet(isPresented: $showRolloverSheet) {
                RolloverSheet(
                    priorities: incompletePriorities,
                    onRollover: { selected in rollOverSelected(selected) }
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

    private var stepTransition: AnyTransition {
        goingForward
            ? .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading))
            : .asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing))
    }

    private func advanceStep() {
        goingForward = true
        withAnimation(.spring(response: 0.3)) {
            currentStep += 1
        }
    }

    // MARK: - Morning Steps

    @ViewBuilder
    private func morningStepView(for step: MorningStep) -> some View {
        switch step {
        case .mood:
            StepCard(title: "How are you feeling this morning?", continueLabel: "Continue", onContinue: advanceStep) {
                moodGrid(selectedMood: $selectedMorningMood, isMorning: true)
            }
        case .priorities:
            StepCard(title: "Today's Priorities", continueLabel: "Continue", onContinue: advanceStep) {
                prioritiesContent
            }
        case .calendarEvents:
            StepCard(title: "Today's Events", continueLabel: "Continue", onContinue: advanceStep) {
                calendarEventsContent
            }
        case .thoughts:
            StepCard(title: "Morning Thoughts", continueLabel: "Continue", onContinue: advanceStep) {
                morningThoughtsContent
            }
            .onAppear { isThoughtsFocused = true }
        case .startDay:
            startMyDayStep
        }
    }

    // MARK: - Evening Steps

    @ViewBuilder
    private func eveningStepView(for step: EveningStep) -> some View {
        switch step {
        case .priorities:
            StepCard(title: "Today's Priorities", continueLabel: "Continue", onContinue: advanceStep) {
                prioritiesContent
            }
        case .mood:
            StepCard(title: "How are you feeling tonight?", continueLabel: "Continue", onContinue: advanceStep) {
                moodGrid(selectedMood: $selectedEveningMood, isMorning: false)
            }
        case .activities:
            StepCard(title: "What shaped your day?", continueLabel: "Continue", onContinue: advanceStep) {
                activitiesGrid
            }
        case .reflection:
            StepCard(title: "Evening Reflection", continueLabel: "Continue", onContinue: advanceStep) {
                eveningReflectionContent
            }
            .onAppear { isReflectionFocused = true }
        case .finishDay:
            finishDayStep
        }
    }

    // MARK: - Greeting (fixed header)

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
    }

    // MARK: - Reusable Step Content

    private func moodGrid(selectedMood: Binding<Mood?>, isMorning: Bool) -> some View {
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

    private var prioritiesContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                if let entry = todayEntry, entry.totalCount >= 2 && timeOfDay.isMorningMode {
                    Button(isReordering ? "Done" : "Reorder") {
                        isReordering.toggle()
                    }
                    .font(.subheadline)
                    .foregroundStyle(Color.warmAccent)
                }

                Spacer()

                if let entry = todayEntry, entry.totalCount > 0 {
                    Text("\(entry.completedCount)/\(entry.totalCount)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            if timeOfDay.isMorningMode && !isReordering {
                HStack {
                    TextField("What matters most today?", text: $newPriorityText)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(Color.warmCardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .onSubmit { addPriority() }

                    Button(action: addPriority) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Color.warmAccent)
                    }
                    .disabled(newPriorityText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }

            if let entry = todayEntry, !entry.prioritiesArray.isEmpty {
                if isReordering {
                    List {
                        ForEach(entry.prioritiesArray) { priority in
                            Text(priority.text ?? "")
                                .strikethrough(priority.isCompleted)
                                .foregroundStyle(priority.isCompleted ? .secondary : .primary)
                                .listRowBackground(Color.warmCardBackground)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                        }
                        .onMove { source, destination in
                            guard let entry = todayEntry else { return }
                            entryManager.reorderPriorities(from: source, to: destination, in: entry)
                            todayEntry = entryManager.getTodayEntry()
                        }
                    }
                    .listStyle(.plain)
                    .scrollDisabled(true)
                    .frame(height: CGFloat(entry.prioritiesArray.count) * 50)
                    .environment(\.editMode, .constant(.active))
                } else {
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
                }
            } else if timeOfDay.isEveningMode {
                Text("No priorities set for today")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            }
        }
    }

    @ViewBuilder
    private var calendarEventsContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(CalendarService.shared.todayEvents, id: \.eventIdentifier) { event in
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
                    Button {
                        addPriorityFromEvent(event)
                    } label: {
                        Image(systemName: "plus.circle")
                            .font(.title3)
                            .foregroundStyle(Color.warmAccent)
                    }
                    .buttonStyle(.borderless)
                }
            }
        }
    }

    private var morningThoughtsContent: some View {
        ZStack(alignment: .topLeading) {
            if morningThoughts.isEmpty {
                Text("What's on your mind as you start the day?")
                    .font(.body)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                    .allowsHitTesting(false)
            }
            TextEditor(text: $morningThoughts)
                .frame(minHeight: 120)
                .scrollContentBackground(.hidden)
                .padding(12)
                .focused($isThoughtsFocused)
                .onChange(of: morningThoughts) { _, newValue in
                    if let entry = todayEntry {
                        entryManager.updateMorningThoughts(newValue, for: entry)
                        showSaved()
                    }
                }
        }
        .background(Color.warmCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var activitiesGrid: some View {
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

    private var eveningReflectionContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
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
                        .focused($isReflectionFocused)
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

    // MARK: - CTA Steps

    private var startMyDayStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                // CTA area
                VStack(spacing: 16) {
                    Image(systemName: showMorningStarted ? "checkmark.circle.fill" : "sun.max.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(showMorningStarted ? Color.green : Color.warmAccent)
                        .animation(.spring(response: 0.3), value: showMorningStarted)

                    Text(showMorningStarted ? "Have a great day! ☀️" : "Ready to start your day?")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .animation(.easeInOut, value: showMorningStarted)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 32)

                Button {
                    lastStartedDayDate = todayDateString
                    withAnimation(.spring(response: 0.3)) { showMorningStarted = true }
                } label: {
                    Text("Start My Day")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color.warmGradientStart, Color.warmGradientEnd],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
                .disabled(showMorningStarted)
                .opacity(showMorningStarted ? 0 : 1)
                .animation(.easeInOut, value: showMorningStarted)

                // Summary — revealed after tapping
                if showMorningStarted {
                    VStack(spacing: 12) {
                        // Mood
                        HStack(spacing: 12) {
                            Image(systemName: "face.smiling")
                                .font(.title3)
                                .foregroundStyle(Color.warmAccent)
                                .frame(width: 28)
                            Text("Mood")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            if let mood = selectedMorningMood {
                                Text("\(mood.emoji) \(mood.rawValue)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            } else {
                                Text("Not set")
                                    .font(.subheadline)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .padding(14)
                        .background(Color.warmCardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                        // Priorities
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.circle")
                                    .font(.title3)
                                    .foregroundStyle(Color.warmAccent)
                                    .frame(width: 28)
                                Text(todayEntry.map { "\($0.totalCount) \($0.totalCount == 1 ? "priority" : "priorities")" } ?? "Priorities")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                            if let entry = todayEntry {
                                ForEach(entry.prioritiesArray) { priority in
                                    HStack(spacing: 8) {
                                        Circle()
                                            .fill(Color.warmAccent.opacity(0.5))
                                            .frame(width: 6, height: 6)
                                        Text(priority.text ?? "")
                                            .font(.subheadline)
                                    }
                                    .padding(.leading, 40)
                                }
                            }
                        }
                        .padding(14)
                        .background(Color.warmCardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                        // Thoughts
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "text.alignleft")
                                .font(.title3)
                                .foregroundStyle(Color.warmAccent)
                                .frame(width: 28)
                            if morningThoughts.isEmpty {
                                Text("No thoughts captured")
                                    .font(.subheadline)
                                    .foregroundStyle(.tertiary)
                            } else {
                                Text(morningThoughts)
                                    .font(.subheadline)
                                    .lineLimit(4)
                            }
                            Spacer()
                        }
                        .padding(14)
                        .background(Color.warmCardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding()
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var finishDayStep: some View {
        VStack {
            Spacer()
            VStack(spacing: 24) {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.warmAccent)

                if let entry = todayEntry {
                    if entry.isCompleted {
                        VStack(spacing: 8) {
                            Text("You're done for today")
                                .font(.title2)
                                .fontWeight(.semibold)
                            Text("Great job capturing your day")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Button {
                            lastFinishedDayDate = todayDateString
                            withAnimation(.spring(response: 0.3)) { showCelebration = true }
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
                                    colors: showCelebration ? [Color.green, Color.green] : [Color(red: 0.95, green: 0.65, blue: 0.50), Color(red: 0.85, green: 0.50, blue: 0.55)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .buttonStyle(.plain)
                        .disabled(showCelebration)
                        .padding(.horizontal)
                    } else {
                        VStack(spacing: 16) {
                            Text("Almost there...")
                                .font(.title2)
                                .fontWeight(.semibold)

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
                            .padding(.horizontal)
                        }
                    }
                }
            }
            Spacer()
        }
        .padding()
    }

    // MARK: - Helpers

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d. MMMM"
        return formatter.string(from: Date())
    }

    private var todayDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    private func formattedEventTime(_ event: EKEvent) -> String {
        if event.isAllDay { return "All day" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return "\(formatter.string(from: event.startDate)) – \(formatter.string(from: event.endDate))"
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

        if let morningMoodString = todayEntry?.morningMood {
            selectedMorningMood = Mood(rawValue: morningMoodString)
        }
        if let eveningMoodString = todayEntry?.eveningMood {
            selectedEveningMood = Mood(rawValue: eveningMoodString)
        }
        if let activitiesString = todayEntry?.eveningActivities {
            let activityNames = activitiesString.split(separator: ",").map { String($0) }
            selectedActivities = Set(activityNames.compactMap { Activity(rawValue: $0) })
        }
    }

    private func addPriorityFromEvent(_ event: EKEvent) {
        guard let entry = todayEntry else { return }
        entryManager.addPriority(text: event.title, to: entry)
        todayEntry = entryManager.getTodayEntry()
        showSaved()
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

    private func showSaved() {
        withAnimation(.easeIn(duration: 0.2)) { showSavedIndicator = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut(duration: 0.3)) { showSavedIndicator = false }
        }
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
        if !trimmed.isEmpty { onEdit(trimmed) }
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
                    Button("Skip All") { dismiss() }
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
                            if isGenerating { ProgressView() }
                        }
                    }
                    .disabled(isGenerating)

                    if let prompt = generatedPrompt {
                        Text(prompt)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .onTapGesture { onSelect(prompt) }
                    }
                }

                Section("From Library") {
                    ForEach(OfflinePrompts.eveningReflection, id: \.self) { prompt in
                        Text(prompt)
                            .font(.subheadline)
                            .onTapGesture { onSelect(prompt) }
                    }
                }
            }
            .navigationTitle("Choose a Prompt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
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
