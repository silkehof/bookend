import CoreData
import Foundation

class DailyEntryManager: ObservableObject {
    static let shared = DailyEntryManager()

    private let viewContext: NSManagedObjectContext

    init(context: NSManagedObjectContext = CoreDataManager.shared.viewContext) {
        self.viewContext = context
    }

    // MARK: - Daily Entry Operations

    func getTodayEntry() -> DailyEntry? {
        let request = DailyEntry.fetchRequest()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        request.predicate = NSPredicate(
            format: "date >= %@ AND date < %@",
            startOfDay as NSDate,
            endOfDay as NSDate
        )
        request.fetchLimit = 1

        return try? viewContext.fetch(request).first
    }

    func getOrCreateTodayEntry() -> DailyEntry {
        if let existing = getTodayEntry() {
            return existing
        }

        let entry = DailyEntry(context: viewContext)
        entry.id = UUID()
        entry.date = Calendar.current.startOfDay(for: Date())
        save()
        return entry
    }

    func getYesterdayEntry() -> DailyEntry? {
        let request = DailyEntry.fetchRequest()
        let calendar = Calendar.current
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) else { return nil }
        let startOfYesterday = calendar.startOfDay(for: yesterday)
        let endOfYesterday = calendar.date(byAdding: .day, value: 1, to: startOfYesterday)!

        request.predicate = NSPredicate(
            format: "date >= %@ AND date < %@",
            startOfYesterday as NSDate,
            endOfYesterday as NSDate
        )
        request.fetchLimit = 1

        return try? viewContext.fetch(request).first
    }

    func getIncompletePrioritiesFromYesterday() -> [Priority] {
        guard let yesterday = getYesterdayEntry() else { return [] }
        return yesterday.prioritiesArray.filter { !$0.isCompleted }
    }

    // MARK: - Priority Operations

    func addPriority(text: String, to entry: DailyEntry) {
        let priority = Priority(context: viewContext)
        priority.id = UUID()
        priority.text = text
        priority.isCompleted = false
        priority.createdAt = Date()
        priority.dailyEntry = entry
        entry.addToPriorities(priority)
        save()
    }

    func togglePriority(_ priority: Priority) {
        priority.isCompleted.toggle()
        save()
    }

    func deletePriority(_ priority: Priority) {
        viewContext.delete(priority)
        save()
    }

    func updatePriorityText(_ priority: Priority, text: String) {
        priority.text = text
        save()
    }

    func rollOverPriority(_ priority: Priority, to entry: DailyEntry) {
        let newPriority = Priority(context: viewContext)
        newPriority.id = UUID()
        newPriority.text = priority.text
        newPriority.isCompleted = false
        newPriority.createdAt = Date()
        newPriority.dailyEntry = entry
        newPriority.rolledOverFromDate = priority.dailyEntry?.date
        entry.addToPriorities(newPriority)
        save()
    }

    // MARK: - Entry Updates

    func updateMorningThoughts(_ thoughts: String, for entry: DailyEntry) {
        entry.morningThoughts = thoughts
        save()
    }

    func updateEveningReflection(_ reflection: String, for entry: DailyEntry) {
        entry.eveningReflection = reflection
        save()
        checkAndLogStreak(for: entry)
    }

    func updateReflectionPrompt(_ prompt: String, for entry: DailyEntry) {
        entry.reflectionPrompt = prompt
        save()
    }

    func updateMorningMood(_ mood: String?, for entry: DailyEntry) {
        entry.morningMood = mood
        save()
    }

    func updateEveningMood(_ mood: String?, for entry: DailyEntry) {
        entry.eveningMood = mood
        save()
    }

    func updateEveningActivities(_ activities: String?, for entry: DailyEntry) {
        entry.eveningActivities = activities
        save()
    }

    func updatePaperJournalStatus(_ status: Bool, for entry: DailyEntry) {
        entry.journaledOnPaper = status
        save()
        checkAndLogStreak(for: entry)
    }

    // MARK: - Streak Tracking

    private func checkAndLogStreak(for entry: DailyEntry) {
        // Only count streak once per day, and only if the day is complete
        guard !entry.streakCounted && entry.isCompleted else { return }

        entry.streakCounted = true
        save()

        // Log to StreakManager on main thread
        Task { @MainActor in
            StreakManager.shared.logJournalEntry()
        }
    }

    // MARK: - Weekly/Monthly Review

    func getEntriesForCurrentWeek() -> [DailyEntry] {
        let request = DailyEntry.fetchRequest()
        let calendar = Calendar.current
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) else {
            return []
        }
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!

        request.predicate = NSPredicate(
            format: "date >= %@ AND date < %@",
            weekStart as NSDate,
            weekEnd as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \DailyEntry.date, ascending: true)]

        return (try? viewContext.fetch(request)) ?? []
    }

    func getEntriesForCurrentMonth() -> [DailyEntry] {
        let request = DailyEntry.fetchRequest()
        let calendar = Calendar.current
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: Date())) else {
            return []
        }
        let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart)!

        request.predicate = NSPredicate(
            format: "date >= %@ AND date < %@",
            monthStart as NSDate,
            monthEnd as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \DailyEntry.date, ascending: true)]

        return (try? viewContext.fetch(request)) ?? []
    }

    // MARK: - Persistence

    private func save() {
        if viewContext.hasChanges {
            try? viewContext.save()
        }
    }
}
