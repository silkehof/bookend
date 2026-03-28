import Foundation

enum Mood: String, CaseIterable, Identifiable {
    case great = "Great"
    case good = "Good"
    case okay = "Okay"
    case low = "Low"
    case stressed = "Stressed"
    case anxious = "Anxious"
    case calm = "Calm"
    case energetic = "Energetic"
    case tired = "Tired"
    case grateful = "Grateful"

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .great: return "😄"
        case .good: return "🙂"
        case .okay: return "😐"
        case .low: return "😔"
        case .stressed: return "😫"
        case .anxious: return "😰"
        case .calm: return "😌"
        case .energetic: return "⚡"
        case .tired: return "😴"
        case .grateful: return "🙏"
        }
    }

    var color: String {
        switch self {
        case .great: return "MoodGreat"
        case .good: return "MoodGood"
        case .okay: return "MoodOkay"
        case .low: return "MoodLow"
        case .stressed: return "MoodStressed"
        case .anxious: return "MoodAnxious"
        case .calm: return "MoodCalm"
        case .energetic: return "MoodEnergetic"
        case .tired: return "MoodTired"
        case .grateful: return "MoodGrateful"
        }
    }
}
