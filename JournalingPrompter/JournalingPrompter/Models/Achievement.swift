import Foundation

struct Achievement: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let requirement: Int
    let type: AchievementType
    var unlockedAt: Date?

    var isUnlocked: Bool { unlockedAt != nil }

    enum AchievementType: String, Codable {
        case streak
        case totalEntries
        case consistency
    }
}

struct AchievementManager {
    static let allAchievements: [Achievement] = [
        // Streak achievements
        Achievement(id: "streak_3", title: "Getting Started", description: "3 day streak", icon: "flame", requirement: 3, type: .streak),
        Achievement(id: "streak_7", title: "One Week Wonder", description: "7 day streak", icon: "flame.fill", requirement: 7, type: .streak),
        Achievement(id: "streak_14", title: "Fortnight Fighter", description: "14 day streak", icon: "bolt.fill", requirement: 14, type: .streak),
        Achievement(id: "streak_30", title: "Monthly Master", description: "30 day streak", icon: "star.fill", requirement: 30, type: .streak),
        Achievement(id: "streak_60", title: "Dedication", description: "60 day streak", icon: "star.circle.fill", requirement: 60, type: .streak),
        Achievement(id: "streak_100", title: "Unstoppable", description: "100 day streak", icon: "crown.fill", requirement: 100, type: .streak),
        Achievement(id: "streak_365", title: "Year of Reflection", description: "365 day streak", icon: "trophy.fill", requirement: 365, type: .streak),

        // Total entries achievements
        Achievement(id: "entries_1", title: "First Words", description: "Write your first entry", icon: "pencil", requirement: 1, type: .totalEntries),
        Achievement(id: "entries_10", title: "Finding Your Voice", description: "10 journal entries", icon: "text.book.closed", requirement: 10, type: .totalEntries),
        Achievement(id: "entries_25", title: "Storyteller", description: "25 journal entries", icon: "book.fill", requirement: 25, type: .totalEntries),
        Achievement(id: "entries_50", title: "Committed Writer", description: "50 journal entries", icon: "books.vertical.fill", requirement: 50, type: .totalEntries),
        Achievement(id: "entries_100", title: "Century", description: "100 journal entries", icon: "medal.fill", requirement: 100, type: .totalEntries),
        Achievement(id: "entries_250", title: "Prolific", description: "250 journal entries", icon: "rosette", requirement: 250, type: .totalEntries),
        Achievement(id: "entries_500", title: "Journal Master", description: "500 journal entries", icon: "trophy.fill", requirement: 500, type: .totalEntries),
    ]
}
