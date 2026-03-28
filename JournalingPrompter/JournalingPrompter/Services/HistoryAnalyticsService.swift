import Foundation
import CoreData

class HistoryAnalyticsService {
    static let shared = HistoryAnalyticsService()
    private let viewContext: NSManagedObjectContext

    init(context: NSManagedObjectContext = CoreDataManager.shared.viewContext) {
        self.viewContext = context
    }

    /// Get mood frequency for a set of entries
    func getMoodFrequency(entries: [DailyEntry]) -> [(mood: Mood, count: Int)] {
        var moodCounts: [Mood: Int] = [:]

        for entry in entries {
            if let morningMood = entry.morningMood, let mood = Mood(rawValue: morningMood) {
                moodCounts[mood, default: 0] += 1
            }
            if let eveningMood = entry.eveningMood, let mood = Mood(rawValue: eveningMood) {
                moodCounts[mood, default: 0] += 1
            }
        }

        return moodCounts.map { (mood: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }

    /// Get average completion rate for a period
    func getCompletionRate(entries: [DailyEntry]) -> Double {
        guard !entries.isEmpty else { return 0.0 }
        let completed = entries.filter { $0.isCompleted }.count
        return Double(completed) / Double(entries.count)
    }

    /// Get average priorities per day
    func getAverageTasksPerDay(entries: [DailyEntry]) -> Double {
        guard !entries.isEmpty else { return 0.0 }
        let totalTasks = entries.reduce(0) { $0 + $1.totalCount }
        return Double(totalTasks) / Double(entries.count)
    }
}
