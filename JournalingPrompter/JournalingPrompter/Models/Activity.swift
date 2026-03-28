import Foundation

enum Activity: String, CaseIterable, Identifiable {
    case work = "Work"
    case exercise = "Exercise"
    case socializing = "Socializing"
    case reading = "Reading"
    case cooking = "Cooking"
    case meditation = "Meditation"
    case creativity = "Creativity"
    case nature = "Nature"
    case learning = "Learning"
    case relaxing = "Relaxing"
    case family = "Family"
    case errands = "Errands"
    case travel = "Travel"
    case entertainment = "Entertainment"
    case selfCare = "Self-Care"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .work: return "briefcase.fill"
        case .exercise: return "figure.run"
        case .socializing: return "person.2.fill"
        case .reading: return "book.fill"
        case .cooking: return "fork.knife"
        case .meditation: return "brain.head.profile"
        case .creativity: return "paintbrush.fill"
        case .nature: return "leaf.fill"
        case .learning: return "graduationcap.fill"
        case .relaxing: return "sofa.fill"
        case .family: return "house.fill"
        case .errands: return "cart.fill"
        case .travel: return "airplane"
        case .entertainment: return "tv.fill"
        case .selfCare: return "heart.fill"
        }
    }
}
