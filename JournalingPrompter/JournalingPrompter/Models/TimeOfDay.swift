import Foundation

enum TimeOfDay: String {
    case earlyMorning = "Early Morning"
    case morning = "Morning"
    case afternoon = "Afternoon"
    case evening = "Evening"
    case night = "Night"

    static var current: TimeOfDay {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<5: return .earlyMorning
        case 5..<12: return .morning
        case 12..<17: return .afternoon
        case 17..<21: return .evening
        default: return .night // 21-24
        }
    }

    var greeting: String {
        switch self {
        case .earlyMorning: return "Good morning"
        case .morning: return "Good morning"
        case .afternoon: return "Good afternoon"
        case .evening: return "Good evening"
        case .night: return "Good evening"
        }
    }

    var contextDescription: String {
        switch self {
        case .earlyMorning: return "starting their day very early"
        case .morning: return "beginning their day"
        case .afternoon: return "in the middle of their day"
        case .evening: return "winding down their day"
        case .night: return "reflecting at night"
        }
    }

    var isMorningMode: Bool {
        switch self {
        case .earlyMorning, .morning, .afternoon: return true
        case .evening, .night: return false
        }
    }

    var isEveningMode: Bool {
        switch self {
        case .evening, .night: return true
        case .earlyMorning, .morning, .afternoon: return false
        }
    }
}
