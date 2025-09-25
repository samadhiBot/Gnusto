import Foundation

// swiftlint:disable sorted_enum_cases

/// Categorizes a character's overall health state for narrative purposes.
public enum HealthCondition {
    /// Character is in excellent health with minimal or no injuries (80-100% health).
    case healthy

    /// Character has minor injuries but remains functional (60-79% health).
    case bruised

    /// Character has sustained moderate injuries that impair performance (40-59% health).
    case wounded

    /// Character has severe injuries requiring immediate attention (20-39% health).
    case badlyWounded

    /// Character is in critical condition and near death (1-19% health).
    case critical

    /// Character has died (0% health).
    case dead

    init(at healthPercent: Int) {
        switch healthPercent {
        case 80...: self = .healthy
        case 60...79: self = .bruised
        case 40...59: self = .wounded
        case 20...39: self = .badlyWounded
        case 1...19: self = .critical
        default: self = .dead
        }
    }
}

// swiftlint:enable sorted_enum_cases
