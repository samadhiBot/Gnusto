import Foundation

/// General character conditions affecting overall state and abilities.
///
/// These represent longer-term conditions that affect the character's capabilities
/// beyond just combat effectiveness. They may persist across multiple encounters.
public enum GeneralCondition: String, Codable, Sendable, Hashable, CaseIterable {
    /// No special conditions affecting the character.
    case normal

    /// Impaired by alcohol consumption.
    ///
    /// Reduces coordination, judgment, and social inhibitions. May make the character
    /// more talkative but less reliable in complex tasks.
    case drunk

    /// Affected by poison or toxins.
    ///
    /// May cause periodic damage, stat reduction, or other ongoing negative effects
    /// until the poison is neutralized or runs its course.
    case poisoned

    /// Suffering from illness or disease.
    ///
    /// Long-term condition that may reduce various abilities and require treatment
    /// or recovery time to overcome.
    case diseased

    /// Under a magical curse or hex.
    ///
    /// Supernatural affliction that may have various negative effects depending
    /// on the specific curse. Usually requires magical means to remove.
    case cursed

    /// Enhanced by magical blessing or divine favor.
    ///
    /// Provides temporary or permanent bonuses to various abilities. The opposite
    /// of a curse, representing divine or magical aid.
    case blessed

    /// Magically compelled to act in certain ways.
    ///
    /// The character's free will is compromised by magical influence, making them
    /// act according to the charm's directives rather than their own desires.
    case charmed

    /// Overcome by supernatural terror.
    ///
    /// The character is paralyzed or compelled to flee by magical or overwhelming fear.
    /// Different from normal fear in its supernatural and debilitating nature.
    case terrified
}

// MARK: - General Condition Properties

extension GeneralCondition {
    /// Whether this condition is generally beneficial to the character.
    public var isBeneficial: Bool {
        self == .blessed
    }

    /// Whether this condition is harmful to the character.
    public var isHarmful: Bool {
        switch self {
        case .normal, .blessed: false
        case .drunk, .poisoned, .diseased, .cursed, .charmed, .terrified: true
        }
    }

    /// Whether this condition affects the character's ability to make free choices.
    public var impairsFreeWill: Bool {
        switch self {
        case .charmed, .terrified: true
        case .normal, .drunk, .poisoned, .diseased, .cursed, .blessed: false
        }
    }

    /// General modifier to ability checks (positive is bonus, negative is penalty).
    public var abilityCheckModifier: Int {
        switch self {
        case .normal: 0
        case .drunk: -2
        case .poisoned: -1
        case .diseased: -2
        case .cursed: -1
        case .blessed: 2
        case .charmed: 0  // No inherent ability penalty
        case .terrified: -3
        }
    }
}
