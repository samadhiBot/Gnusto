import Foundation

// swiftlint:disable sorted_enum_cases

/// Character alignment representing moral and ethical orientation.
///
/// Based on the classic D&D alignment system, this enum combines two axes:
/// the Law/Chaos axis (attitude toward order and rules) and the Good/Evil axis
/// (moral orientation toward others). Alignment affects dialogue options,
/// pacification difficulty, and various social interactions.
public enum Alignment: String, Codable, Sendable, Hashable, CaseIterable {
    /// Upholds law and order while acting for the greater good.
    ///
    /// Lawful good characters are crusaders, paladins, and honorable knights.
    /// They believe in doing the right thing through proper channels and established systems.
    case lawfulGood

    /// Acts for the greater good without strict adherence to law or chaos.
    ///
    /// Neutral good characters are altruists who help others but aren't bound
    /// by rigid codes. They adapt their methods to the situation at hand.
    case neutralGood

    /// Does good through freedom and flexibility, often defying unjust laws.
    ///
    /// Chaotic good characters are free spirits and rebels with hearts of gold.
    /// They prioritize individual freedom and doing what's right over following rules.
    case chaoticGood

    /// Follows law and order but isn't particularly motivated by good or evil.
    ///
    /// Lawful neutral characters are judges, soldiers, and bureaucrats who
    /// believe in structure and tradition above personal moral considerations.
    case lawfulNeutral

    /// Maintains balance and neutrality, avoiding extreme positions.
    ///
    /// True neutral characters are druids, diplomats, and those who see
    /// the value in all perspectives. They often serve as mediators.
    case trueNeutral

    /// Values personal freedom above law or moral considerations.
    ///
    /// Chaotic neutral characters are unpredictable free spirits who
    /// follow their whims and desires without consistent moral framework.
    case chaoticNeutral

    /// Uses law and order as tools for personal gain and control over others.
    ///
    /// Lawful evil characters are tyrants, corrupt nobles, and organized crime leaders
    /// who believe in hierarchy with themselves at the top.
    case lawfulEvil

    /// Pursues selfish goals without regard for law or chaos.
    ///
    /// Neutral evil characters are pure opportunists who will use any means
    /// necessary to achieve their ends, caring only for themselves.
    case neutralEvil

    /// Embraces chaos and destruction for personal satisfaction.
    ///
    /// Chaotic evil characters are demons, psychopaths, and those who revel
    /// in causing suffering and mayhem without any greater purpose.
    case chaoticEvil
}

// MARK: - Alignment Axes

extension Alignment {
    /// The lawful/chaotic axis of this alignment.
    public var lawChaosAxis: LawChaosAxis {
        switch self {
        case .lawfulGood, .lawfulNeutral, .lawfulEvil:
            return .lawful
        case .neutralGood, .trueNeutral, .neutralEvil:
            return .neutral
        case .chaoticGood, .chaoticNeutral, .chaoticEvil:
            return .chaotic
        }
    }

    /// The good/evil axis of this alignment.
    public var goodEvilAxis: GoodEvilAxis {
        switch self {
        case .lawfulGood, .neutralGood, .chaoticGood:
            return .good
        case .lawfulNeutral, .trueNeutral, .chaoticNeutral:
            return .neutral
        case .lawfulEvil, .neutralEvil, .chaoticEvil:
            return .evil
        }
    }
}

// MARK: - Behavioral Properties

extension Alignment {
    /// Whether this alignment can be pacified through dialogue.
    ///
    /// Good and neutral alignments are generally more open to peaceful resolution.
    public var canBePacified: Bool {
        switch goodEvilAxis {
        case .good: true
        case .neutral: true
        case .evil: false
        }
    }

    /// Base difficulty class for pacifying this character through dialogue.
    ///
    /// Lower values are easier to pacify. Evil alignments return high values.
    public var basePacifyDC: Int {
        switch self {
        case .lawfulGood: 12 + 4
        case .neutralGood: 8 + 4
        case .chaoticGood: 4 + 4
        case .lawfulNeutral: 12 + 8
        case .trueNeutral: 8 + 8
        case .chaoticNeutral: 4 + 8
        case .lawfulEvil: 12 + 12
        case .neutralEvil: 8 + 12
        case .chaoticEvil: 4 + 12
        }
    }

    /// Whether this alignment typically requires weapons for effective combat.
    ///
    /// Chaotic and evil alignments are more likely to fight dirty and unarmed.
    public var requiresWeapon: Bool {
        switch self {
        case .lawfulGood, .lawfulNeutral, .lawfulEvil:
            return true
        case .neutralGood, .trueNeutral, .neutralEvil:
            return false
        case .chaoticGood, .chaoticNeutral, .chaoticEvil:
            return false
        }
    }

    /// Base morale modifier for this alignment.
    ///
    /// Affects fear resistance and willingness to continue fighting.
    public var moraleModifier: Int {
        switch self {
        case .lawfulGood: 2
        case .neutralGood: 1
        case .chaoticGood: 0
        case .lawfulNeutral: 1
        case .trueNeutral: 0
        case .chaoticNeutral: -1
        case .lawfulEvil: 1
        case .neutralEvil: -1
        case .chaoticEvil: -2
        }
    }

    /// Base intimidation modifier for this alignment.
    ///
    /// Evil alignments are naturally more intimidating.
    public var intimidationModifier: Int {
        switch goodEvilAxis {
        case .good: -1
        case .neutral: 0
        case .evil: 2
        }
    }
}

// MARK: - Supporting Enums

/// The lawful/chaotic axis of character alignment.
public enum LawChaosAxis: String, Codable, Sendable, Hashable {
    /// Respects law, order, and established systems.
    case lawful

    /// Balances law and chaos based on circumstances.
    case neutral

    /// Values freedom and spontaneity over rules.
    case chaotic
}

/// The good/evil axis of character alignment.
public enum GoodEvilAxis: String, Codable, Sendable, Hashable {
    /// Acts for the benefit of others and the greater good.
    case good

    /// Neither particularly altruistic nor malicious.
    case neutral

    /// Acts primarily for selfish gain, often harming others.
    case evil
}

// swiftlint:enable sorted_enum_cases
