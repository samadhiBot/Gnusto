import Foundation

/// Categorizes a character's overall health state for narrative purposes.
public enum HealthCondition {
    case healthy  // 80-100%
    case bruised  // 60-79%
    case wounded  // 40-59%
    case badlyWounded  // 20-39%
    case critical  // 1-19%
    case dead  // 0%

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
