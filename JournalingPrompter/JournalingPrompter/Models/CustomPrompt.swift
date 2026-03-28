import Foundation

struct CustomPrompt: Codable, Identifiable, Equatable {
    let id: UUID
    let text: String
    let mood: String?      // Optional mood to show for
    let activity: String?  // Optional activity to show for
    let createdAt: Date

    init(text: String, mood: Mood? = nil, activity: Activity? = nil) {
        self.id = UUID()
        self.text = text
        self.mood = mood?.rawValue
        self.activity = activity?.rawValue
        self.createdAt = Date()
    }

    var moodEnum: Mood? {
        guard let mood = mood else { return nil }
        return Mood(rawValue: mood)
    }

    var activityEnum: Activity? {
        guard let activity = activity else { return nil }
        return Activity(rawValue: activity)
    }

    func matches(mood: Mood?, activity: Activity?) -> Bool {
        // If no filters set, always matches
        if self.mood == nil && self.activity == nil {
            return true
        }

        // Check mood match
        if let promptMood = self.mood, let selectedMood = mood {
            if promptMood == selectedMood.rawValue {
                return true
            }
        }

        // Check activity match
        if let promptActivity = self.activity, let selectedActivity = activity {
            if promptActivity == selectedActivity.rawValue {
                return true
            }
        }

        // If filters set but don't match
        if self.mood != nil || self.activity != nil {
            return false
        }

        return true
    }
}
