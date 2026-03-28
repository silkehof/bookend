import CoreData
import Foundation

@objc(DailyEntry)
public class DailyEntry: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var date: Date?
    @NSManaged public var morningThoughts: String?
    @NSManaged public var morningMood: String?
    @NSManaged public var eveningReflection: String?
    @NSManaged public var eveningMood: String?
    @NSManaged public var eveningActivities: String?
    @NSManaged public var reflectionPrompt: String?
    @NSManaged public var priorities: NSSet?
    @NSManaged public var streakCounted: Bool
    @NSManaged public var journaledOnPaper: Bool

    public var prioritiesArray: [Priority] {
        let set = priorities as? Set<Priority> ?? []
        return set.sorted { ($0.createdAt ?? Date()) < ($1.createdAt ?? Date()) }
    }

    public var completedCount: Int {
        prioritiesArray.filter { $0.isCompleted }.count
    }

    public var totalCount: Int {
        prioritiesArray.count
    }

    public var formattedDate: String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: date)
    }

    public var isToday: Bool {
        guard let date = date else { return false }
        return Calendar.current.isDateInToday(date)
    }

    /// A day is complete when it has an evening reflection OR journaled on paper
    public var isCompleted: Bool {
        let hasReflection = !(eveningReflection ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasPaperJournal = journaledOnPaper

        return hasReflection || hasPaperJournal
    }
}

extension DailyEntry {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<DailyEntry> {
        return NSFetchRequest<DailyEntry>(entityName: "DailyEntry")
    }

    @objc(addPrioritiesObject:)
    @NSManaged public func addToPriorities(_ value: Priority)

    @objc(removePrioritiesObject:)
    @NSManaged public func removeFromPriorities(_ value: Priority)

    @objc(addPriorities:)
    @NSManaged public func addToPriorities(_ values: NSSet)

    @objc(removePriorities:)
    @NSManaged public func removeFromPriorities(_ values: NSSet)
}
