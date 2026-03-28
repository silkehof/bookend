import SwiftUI
import CoreData

struct HistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \DailyEntry.date, ascending: false)],
        animation: .default
    )
    private var entries: FetchedResults<DailyEntry>

    @State private var selectedEntry: DailyEntry?

    var body: some View {
        NavigationStack {
            Group {
                if entries.isEmpty {
                    emptyState
                } else {
                    entriesList
                }
            }
            .navigationTitle("History")
            .sheet(item: $selectedEntry) { entry in
                DailyEntryDetailView(entry: entry)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar")
                .font(.system(size: 60))
                .foregroundStyle(Color.warmSecondary)

            Text("No Days Yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Your daily entries will appear here once you start journaling.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }

    private var entriesList: some View {
        List {
            ForEach(groupedEntries, id: \.key) { section in
                Section(header: Text(section.key)) {
                    ForEach(section.value) { entry in
                        DailyEntryRow(entry: entry)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedEntry = entry
                            }
                            .listRowBackground(
                                moodBackgroundColor(for: entry)
                                    .opacity(0.1)
                            )
                    }
                    .onDelete { indexSet in
                        deleteEntries(at: indexSet, in: section.value)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func moodBackgroundColor(for entry: DailyEntry) -> Color {
        // Use evening mood if available, otherwise morning mood
        let moodString = entry.eveningMood ?? entry.morningMood ?? ""
        guard let mood = Mood(rawValue: moodString) else { return .clear }

        switch mood {
        case .great, .good, .grateful: return .green
        case .okay: return .blue
        case .calm: return .cyan
        case .energetic: return .orange
        case .tired: return .indigo
        case .low, .anxious, .stressed: return .purple
        }
    }

    private var groupedEntries: [(key: String, value: [DailyEntry])] {
        let grouped = Dictionary(grouping: entries) { entry -> String in
            guard let date = entry.date else { return "Unknown" }
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: date)
        }
        return grouped.sorted { $0.key > $1.key }
    }

    private func deleteEntries(at offsets: IndexSet, in sectionEntries: [DailyEntry]) {
        for index in offsets {
            let entry = sectionEntries[index]
            viewContext.delete(entry)
        }
        try? viewContext.save()
    }
}

// MARK: - Daily Entry Row

struct DailyEntryRow: View {
    let entry: DailyEntry

    var body: some View {
        HStack(spacing: 12) {
            // Completion status circle
            Circle()
                .fill(entry.isCompleted ? Color.green : Color.secondary.opacity(0.3))
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    // Mood journey
                    moodJourney

                    Spacer()

                    // Priority completion dots instead of text
                    if entry.totalCount > 0 {
                        priorityDots
                    }
                }

                // Date
                Text(formattedDate)
                    .font(.subheadline)
                    .fontWeight(.medium)

                // Reflection preview
                if let reflection = entry.eveningReflection, !reflection.isEmpty {
                    Text(reflection)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                } else if let thoughts = entry.morningThoughts, !thoughts.isEmpty {
                    Text(thoughts)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                } else if entry.journaledOnPaper {
                    HStack(spacing: 4) {
                        Image(systemName: "book.closed")
                        Text("Journaled on paper")
                    }
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var priorityDots: some View {
        HStack(spacing: 3) {
            ForEach(0..<min(entry.totalCount, 10), id: \.self) { index in
                Circle()
                    .fill(index < entry.completedCount ? Color.green : Color.secondary.opacity(0.3))
                    .frame(width: 6, height: 6)
            }
            if entry.totalCount > 10 {
                Text("+\(entry.totalCount - 10)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var moodJourney: some View {
        HStack(spacing: 4) {
            if let morningMood = entry.morningMood, let mood = Mood(rawValue: morningMood) {
                Text(mood.emoji)
            }

            if entry.morningMood != nil && entry.eveningMood != nil {
                Image(systemName: "arrow.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            if let eveningMood = entry.eveningMood, let mood = Mood(rawValue: eveningMood) {
                Text(mood.emoji)
            }
        }
    }

    private var formattedDate: String {
        guard let date = entry.date else { return "Unknown date" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Daily Entry Detail View

struct DailyEntryDetailView: View {
    let entry: DailyEntry
    @Environment(\.dismiss) private var dismiss
    @State private var isEditing = false
    @State private var morningThoughtsEdit: String
    @State private var eveningReflectionEdit: String

    init(entry: DailyEntry) {
        self.entry = entry
        _morningThoughtsEdit = State(initialValue: entry.morningThoughts ?? "")
        _eveningReflectionEdit = State(initialValue: entry.eveningReflection ?? "")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if hasMorningContent || isEditing {
                        morningSection
                    }

                    if entry.totalCount > 0 {
                        prioritiesSection
                    }

                    if hasEveningContent || isEditing {
                        eveningSection
                    }
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(formattedDate)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if isEditing {
                        Button("Cancel") {
                            morningThoughtsEdit = entry.morningThoughts ?? ""
                            eveningReflectionEdit = entry.eveningReflection ?? ""
                            isEditing = false
                        }
                    } else {
                        Button {
                            isEditing = true
                        } label: {
                            Image(systemName: "pencil")
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isEditing {
                        Button("Save") {
                            saveEdits()
                            isEditing = false
                        }
                        .fontWeight(.semibold)
                    } else {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
            }
        }
    }

    private var hasMorningContent: Bool {
        entry.morningMood != nil || !(entry.morningThoughts ?? "").isEmpty
    }

    private var hasEveningContent: Bool {
        entry.eveningMood != nil || !(entry.eveningReflection ?? "").isEmpty
    }

    private func saveEdits() {
        let manager = DailyEntryManager.shared
        manager.updateMorningThoughts(morningThoughtsEdit, for: entry)
        manager.updateEveningReflection(eveningReflectionEdit, for: entry)
    }

    private var morningSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Morning", systemImage: "sunrise.fill")
                .font(.headline)
                .foregroundStyle(Color.warmAccent)

            if let moodString = entry.morningMood, let mood = Mood(rawValue: moodString) {
                HStack {
                    Text(mood.emoji)
                    Text(mood.rawValue)
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline)
            }

            if isEditing {
                TextEditor(text: $morningThoughtsEdit)
                    .frame(minHeight: 100)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .background(Color.warmSecondary.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else if let thoughts = entry.morningThoughts, !thoughts.isEmpty {
                Text(thoughts)
                    .font(.body)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.warmCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var prioritiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Priorities", systemImage: "checklist")
                    .font(.headline)

                Spacer()

                Text("\(entry.completedCount)/\(entry.totalCount) completed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ForEach(entry.prioritiesArray) { priority in
                HStack(spacing: 12) {
                    Image(systemName: priority.isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(priority.isCompleted ? Color.green : Color.secondary)

                    Text(priority.text ?? "")
                        .strikethrough(priority.isCompleted)
                        .foregroundStyle(priority.isCompleted ? .secondary : .primary)
                }
                .font(.subheadline)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.warmCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var eveningSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Evening", systemImage: "moon.fill")
                .font(.headline)
                .foregroundStyle(Color.warmAccent)

            if let moodString = entry.eveningMood, let mood = Mood(rawValue: moodString) {
                HStack {
                    Text(mood.emoji)
                    Text(mood.rawValue)
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline)
            }

            if let activitiesString = entry.eveningActivities, !activitiesString.isEmpty {
                let activities = activitiesString.split(separator: ",").compactMap { Activity(rawValue: String($0)) }
                if !activities.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(activities, id: \.self) { activity in
                            HStack(spacing: 4) {
                                Image(systemName: activity.icon)
                                Text(activity.rawValue)
                            }
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.warmAccent.opacity(0.15))
                            .clipShape(Capsule())
                        }
                    }
                }
            }

            if let prompt = entry.reflectionPrompt, !prompt.isEmpty {
                Text(prompt)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .italic()
            }

            if isEditing {
                TextEditor(text: $eveningReflectionEdit)
                    .frame(minHeight: 120)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .background(Color.warmSecondary.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else if let reflection = entry.eveningReflection, !reflection.isEmpty {
                Text(reflection)
                    .font(.body)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.warmCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var formattedDate: String {
        guard let date = entry.date else { return "Entry" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: date)
    }
}

#Preview {
    HistoryView()
}
