import Foundation
import SwiftUI

@MainActor
class StreakManager: ObservableObject {
    static let shared = StreakManager()

    @AppStorage("currentStreak") private var currentStreakStored = 0
    @AppStorage("longestStreak") private var longestStreakStored = 0
    @AppStorage("totalEntries") private var totalEntriesStored = 0
    @AppStorage("lastJournalDate") private var lastJournalDateStored: Double = 0
    @AppStorage("weeklyEntries") private var weeklyEntriesStored = 0
    @AppStorage("weekStartDate") private var weekStartDateStored: Double = 0
    @AppStorage("unlockedAchievements") private var unlockedAchievementsData: Data = Data()

    @Published var currentStreak: Int = 0
    @Published var longestStreak: Int = 0
    @Published var totalEntries: Int = 0
    @Published var journaledToday: Bool = false
    @Published var weeklyEntries: Int = 0
    @Published var unlockedAchievements: Set<String> = []
    @Published var newlyUnlockedAchievement: Achievement?

    private var lastJournalDate: Date? {
        get { lastJournalDateStored == 0 ? nil : Date(timeIntervalSince1970: lastJournalDateStored) }
        set { lastJournalDateStored = newValue?.timeIntervalSince1970 ?? 0 }
    }

    init() {
        loadStats()
        checkStreakStatus()
        checkWeekReset()
    }

    private func loadStats() {
        currentStreak = currentStreakStored
        longestStreak = longestStreakStored
        totalEntries = totalEntriesStored
        weeklyEntries = weeklyEntriesStored

        if let decoded = try? JSONDecoder().decode(Set<String>.self, from: unlockedAchievementsData) {
            unlockedAchievements = decoded
        }
    }

    private func saveStats() {
        currentStreakStored = currentStreak
        longestStreakStored = longestStreak
        totalEntriesStored = totalEntries
        weeklyEntriesStored = weeklyEntries

        if let encoded = try? JSONEncoder().encode(unlockedAchievements) {
            unlockedAchievementsData = encoded
        }
    }

    private func checkWeekReset() {
        let calendar = Calendar.current
        let now = Date()
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!

        if weekStartDateStored == 0 || Date(timeIntervalSince1970: weekStartDateStored) < weekStart {
            weeklyEntries = 0
            weekStartDateStored = weekStart.timeIntervalSince1970
            saveStats()
        }
    }

    func checkStreakStatus() {
        guard let lastDate = lastJournalDate else {
            journaledToday = false
            return
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastDay = calendar.startOfDay(for: lastDate)

        journaledToday = calendar.isDate(lastDay, inSameDayAs: today)

        if let daysDiff = calendar.dateComponents([.day], from: lastDay, to: today).day {
            if daysDiff > 1 {
                currentStreak = 0
                saveStats()
            }
        }
    }

    func logJournalEntry() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let lastDate = lastJournalDate {
            let lastDay = calendar.startOfDay(for: lastDate)
            if calendar.isDate(lastDay, inSameDayAs: today) {
                totalEntries += 1
                weeklyEntries += 1
                saveStats()
                checkAchievements()
                return
            }

            if let daysDiff = calendar.dateComponents([.day], from: lastDay, to: today).day {
                if daysDiff == 1 {
                    currentStreak += 1
                } else if daysDiff > 1 {
                    currentStreak = 1
                }
            }
        } else {
            currentStreak = 1
        }

        totalEntries += 1
        weeklyEntries += 1
        lastJournalDate = Date()
        journaledToday = true

        if currentStreak > longestStreak {
            longestStreak = currentStreak
        }

        saveStats()
        checkAchievements()
    }

    private func checkAchievements() {
        for achievement in AchievementManager.allAchievements {
            if unlockedAchievements.contains(achievement.id) { continue }

            var shouldUnlock = false

            switch achievement.type {
            case .streak:
                shouldUnlock = currentStreak >= achievement.requirement
            case .totalEntries:
                shouldUnlock = totalEntries >= achievement.requirement
            case .consistency:
                break
            }

            if shouldUnlock {
                unlockedAchievements.insert(achievement.id)
                newlyUnlockedAchievement = achievement
                saveStats()
            }
        }
    }

    func clearNewAchievement() {
        newlyUnlockedAchievement = nil
    }

    // MARK: - Display helpers

    var level: Int {
        switch totalEntries {
        case 0: return 1
        case 1...9: return 2
        case 10...24: return 3
        case 25...49: return 4
        case 50...99: return 5
        case 100...249: return 6
        case 250...499: return 7
        default: return 8
        }
    }

    var levelName: String {
        switch level {
        case 1: return "Seedling"
        case 2: return "Sprout"
        case 3: return "Sapling"
        case 4: return "Growing Tree"
        case 5: return "Blooming Tree"
        case 6: return "Mighty Oak"
        case 7: return "Ancient Tree"
        default: return "Tree of Wisdom"
        }
    }

    var levelIcon: String {
        switch level {
        case 1: return "leaf"
        case 2: return "leaf.fill"
        case 3: return "tree"
        case 4: return "tree.fill"
        case 5: return "sparkles"
        case 6: return "star.fill"
        case 7: return "crown"
        default: return "crown.fill"
        }
    }

    var progressToNextLevel: Double {
        let thresholds = [0, 1, 10, 25, 50, 100, 250, 500]
        let currentLevel = level - 1
        if currentLevel >= thresholds.count - 1 { return 1.0 }

        let currentThreshold = thresholds[currentLevel]
        let nextThreshold = thresholds[currentLevel + 1]
        let progress = Double(totalEntries - currentThreshold) / Double(nextThreshold - currentThreshold)
        return min(max(progress, 0), 1)
    }

    var entriesToNextLevel: Int {
        let thresholds = [0, 1, 10, 25, 50, 100, 250, 500]
        let currentLevel = level - 1
        if currentLevel >= thresholds.count - 1 { return 0 }
        return thresholds[currentLevel + 1] - totalEntries
    }

    var streakEmoji: String {
        switch currentStreak {
        case 0: return "🌱"
        case 1...2: return "🌿"
        case 3...6: return "🌳"
        case 7...13: return "🔥"
        case 14...29: return "⭐"
        case 30...59: return "💫"
        case 60...99: return "🌟"
        default: return "👑"
        }
    }

    var encouragement: String {
        if !journaledToday {
            switch currentStreak {
            case 0: return "Start your journey today!"
            case 1...2: return "Keep the momentum going!"
            case 3...6: return "You're building a great habit!"
            case 7...13: return "A whole week! Don't break it!"
            default: return "Your streak is impressive!"
            }
        } else {
            switch currentStreak {
            case 1: return "Great start! See you tomorrow."
            case 2...6: return "You're doing amazing!"
            case 7...13: return "One week strong! 💪"
            case 14...29: return "Two weeks of growth!"
            case 30...59: return "A month of reflection!"
            default: return "You're a journaling master!"
            }
        }
    }
}
