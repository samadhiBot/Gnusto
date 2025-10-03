import Foundation

/// Comprehensive character sheet containing all attributes, properties, and states for NPCs and characters.
///
/// This serves as the single source of truth for character-related data, combining D&D-style
/// attributes, combat behavior settings, character states, and grammatical properties.
/// Many combat properties are computed from core attributes and alignment rather than stored directly.
public struct CharacterSheet: Sendable, Hashable, Codable {

    // MARK: - Core Attributes

    /// Physical power - affects melee damage and ability to carry items.
    public var strength: Int

    /// Agility and reflexes - affects accuracy, dodge chance, and initiative.
    public var dexterity: Int

    /// Endurance and health - affects hit points and resistance to damage.
    public var constitution: Int

    /// Reasoning and memory - affects puzzle-solving and magic use.
    public var intelligence: Int

    /// Awareness and intuition - affects will saves and base perception.
    public var wisdom: Int

    /// Force of personality - affects social interactions and leadership.
    public var charisma: Int

    /// Courage and willpower - affects resistance to fear and intimidation.
    public var bravery: Int

    // MARK: - Secondary Attributes

    /// Awareness of surroundings - affects initiative, spotting hidden things, and surprise detection.
    public var perception: Int

    /// Random fortune - affects critical hits, saving throws, and random events.
    public var luck: Int

    /// Mental fortitude and fighting spirit - affects fleeing behavior and fear resistance.
    public var morale: Int

    /// Precision with ranged weapons - affects ranged attack rolls.
    public var accuracy: Int

    /// Ability to frighten and cow opponents - affects pacification attempts.
    public var intimidation: Int

    /// Ability to move unseen and unheard - affects surprise attacks and hiding.
    public var stealth: Int

    // MARK: - Combat Statistics

    /// Armor class representing how hard the character is to hit.
    public var armorClass: Int

    /// Current health/hit points.
    public var health: Int

    /// Maximum health/hit points.
    public var maxHealth: Int

    /// Character level for experience-based progression.
    public var level: Int

    // MARK: - Character Properties

    /// Grammatical classification for pronoun usage and natural language generation.
    public var classification: Classification

    /// Moral and ethical alignment affecting behavior and dialogue options.
    public var alignment: Alignment

    // MARK: - Character States

    /// Current level of consciousness and awareness.
    public var consciousness: ConsciousnessLevel

    /// Temporary combat condition affecting fighting effectiveness.
    public var combatCondition: CombatCondition

    /// General condition affecting overall abilities and state.
    public var generalCondition: GeneralCondition

    /// Whether this character is currently engaged in combat.
    public var isFighting: Bool

    // MARK: - Character-Specific Combat Settings

    /// Special weaknesses to specific weapons (bonus damage).
    public let weaponWeaknesses: [ItemID: Int]

    /// Special resistances to specific weapons (reduced damage).
    public let weaponResistances: [ItemID: Int]

    /// Taunts this character might use during combat.
    public let taunts: [String]

    // MARK: - Initialization

    /// Creates a comprehensive character sheet with specified values.
    ///
    /// - Parameters:
    ///   - strength: Physical power (default: 10)
    ///   - dexterity: Agility and reflexes (default: 10)
    ///   - constitution: Endurance and health (default: 10)
    ///   - intelligence: Reasoning and memory (default: 10)
    ///   - wisdom: Awareness and intuition (default: 10)
    ///   - charisma: Force of personality (default: 10)
    ///   - bravery: Courage and willpower (default: 10)
    ///   - perception: Awareness of surroundings (default: 10)
    ///   - luck: Random fortune (default: 10)
    ///   - morale: Mental fortitude (default: 10)
    ///   - accuracy: Ranged precision (default: 10)
    ///   - intimidation: Ability to frighten (default: 10)
    ///   - stealth: Ability to hide (default: 10)
    ///   - level: Character level (default: 1)
    ///   - classification: Grammatical gender (default: .neuter)
    ///   - alignment: Moral alignment (default: .trueNeutral)
    ///   - armorClass: Armor class (computed if nil)
    ///   - health: Current health (computed if nil)
    ///   - maxHealth: Maximum health (computed if nil)
    ///   - consciousness: Level of awareness (default: .awake)
    ///   - combatCondition: Combat state (default: .normal)
    ///   - generalCondition: General state (default: .normal)
    ///   - isFighting: Currently in combat (default: false)
    ///   - weaponWeaknesses: Weapon vulnerabilities (default: empty)
    ///   - weaponResistances: Weapon resistances (default: empty)
    ///   - taunts: Combat taunts (default: empty)
    public init(
        strength: Int = 10,
        dexterity: Int = 10,
        constitution: Int = 10,
        intelligence: Int = 10,
        wisdom: Int = 10,
        charisma: Int = 10,
        bravery: Int = 10,
        perception: Int = 10,
        luck: Int = 10,
        morale: Int = 10,
        accuracy: Int = 10,
        intimidation: Int = 10,
        stealth: Int = 10,
        level: Int = 1,
        classification: Classification = .neuter,
        alignment: Alignment = .trueNeutral,
        armorClass: Int? = nil,
        health: Int? = nil,
        maxHealth: Int? = nil,
        consciousness: ConsciousnessLevel = .alert,
        combatCondition: CombatCondition = .normal,
        generalCondition: GeneralCondition = .normal,
        isFighting: Bool = false,
        weaponWeaknesses: [ItemID: Int] = [:],
        weaponResistances: [ItemID: Int] = [:],
        taunts: [String] = []
    ) {
        // Computed values
        let computedHealth = 50 + ((constitution - 10) / 2) + (level / 2)
        let computedArmorClass = 10 + ((dexterity - 10) / 2) + (level / 2)

        // Core attributes
        self.strength = strength
        self.dexterity = dexterity
        self.constitution = constitution
        self.intelligence = intelligence
        self.wisdom = wisdom
        self.charisma = charisma
        self.bravery = bravery

        // Additional combat attributes
        self.perception = perception
        self.luck = luck
        self.morale = morale
        self.accuracy = accuracy
        self.intimidation = intimidation
        self.stealth = stealth

        // Combat statistics
        self.level = level
        self.armorClass = armorClass ?? computedArmorClass
        self.health = health ?? computedHealth
        self.maxHealth = maxHealth ?? health ?? computedHealth

        // Character properties
        self.classification = classification
        self.alignment = alignment

        // Character states
        self.consciousness = consciousness
        self.combatCondition = combatCondition
        self.generalCondition = generalCondition
        self.isFighting = isFighting

        // Character-specific combat settings
        self.weaponWeaknesses = weaponWeaknesses
        self.weaponResistances = weaponResistances
        self.taunts = taunts
    }
}

// MARK: - Predefined Character Sheets

extension CharacterSheet {
    /// Character sheet for an agile enemy (e.g., thief, assassin).
    public static let agile = CharacterSheet(
        strength: 10,
        dexterity: 18,
        constitution: 10,
        intelligence: 12,
        wisdom: 13,
        charisma: 10,
        bravery: 12,
        perception: 16,
        luck: 14,
        morale: 12,
        accuracy: 16,
        intimidation: 8,
        stealth: 18,
        alignment: .chaoticNeutral,
        armorClass: 9,
        health: 60
    )

    /// Character sheet for a boss enemy (e.g., dragon).
    public static let boss = CharacterSheet(
        strength: 18,
        dexterity: 12,
        constitution: 16,
        intelligence: 18,
        wisdom: 15,
        charisma: 12,
        bravery: 18,
        perception: 16,
        luck: 12,
        morale: 18,
        accuracy: 14,
        intimidation: 16,
        stealth: 8,
        level: 5,
        alignment: .chaoticEvil
    )

    /// Default character sheet for an average NPC.
    public static let `default` = CharacterSheet()

    /// Character sheet for a strong enemy (e.g., ogre, troll).
    public static let strong = CharacterSheet(
        strength: 18,
        dexterity: 8,
        constitution: 16,
        intelligence: 6,
        wisdom: 8,
        charisma: 6,
        bravery: 14,
        perception: 10,
        luck: 8,
        morale: 16,
        accuracy: 8,
        intimidation: 14,
        stealth: 6,
        alignment: .chaoticEvil,
        armorClass: 9,
        health: 90
    )

    /// Character sheet for a weak enemy (e.g., rat, goblin).
    public static let weak = CharacterSheet(
        strength: 6,
        constitution: 6,
        intelligence: 8,
        wisdom: 6,
        charisma: 4,
        bravery: 4,
        perception: 8,
        morale: 6,
        accuracy: 6,
        intimidation: 2,
        alignment: .chaoticEvil,
        health: 20
    )

    /// Character sheet for a wise character (e.g., wizard, sage).
    public static let wise = CharacterSheet(
        strength: 8,
        intelligence: 18,
        wisdom: 16,
        perception: 14,
        morale: 14,
        intimidation: 14,
        alignment: .chaoticGood,
        health: 60
    )
}

extension CharacterSheet {
    /// Returns a character sheet with `.isFighting` set to true.
    public var enemy: CharacterSheet {
        var copy = self
        copy.isFighting = true
        return copy
    }
}

// MARK: - Attribute Modifiers

extension CharacterSheet {
    /// Calculates the D&D-style modifier for an attribute value.
    ///
    /// The modifier is (attribute - 10) / 2, rounded down.
    /// For example: 18 gives +4, 10 gives +0, 6 gives -2.
    private func modifier(for value: Int) -> Int {
        (value - 10) / 2
    }

    /// Strength modifier - affects melee attack and damage rolls.
    public var strengthModifier: Int { modifier(for: strength) }

    /// Dexterity modifier - affects ranged attack, AC, and initiative.
    public var dexterityModifier: Int { modifier(for: dexterity) }

    /// Constitution modifier - affects hit points and fortitude saves.
    public var constitutionModifier: Int { modifier(for: constitution) }

    /// Intelligence modifier - affects skill points and knowledge checks.
    public var intelligenceModifier: Int { modifier(for: intelligence) }

    /// Wisdom modifier - affects will saves and perception.
    public var wisdomModifier: Int { modifier(for: wisdom) }

    /// Charisma modifier - affects social interactions.
    public var charismaModifier: Int { modifier(for: charisma) }

    /// Bravery modifier - affects fear resistance and morale.
    public var braveryModifier: Int { modifier(for: bravery) }

    /// Perception modifier - affects awareness and initiative.
    public var perceptionModifier: Int { modifier(for: perception) }

    /// Luck modifier - affects critical hits and saving throws.
    public var luckModifier: Int { modifier(for: luck) }

    /// Morale modifier - affects fear resistance and fleeing behavior.
    public var moraleModifier: Int { modifier(for: morale) }

    /// Accuracy modifier - affects ranged attack rolls.
    public var accuracyModifier: Int { modifier(for: accuracy) }

    /// Intimidation modifier - affects fear-based attacks.
    public var intimidationModifier: Int { modifier(for: intimidation) }

    /// Stealth modifier - affects hiding and surprise attacks.
    public var stealthModifier: Int { modifier(for: stealth) }
}

// MARK: - Computed Combat Properties

extension CharacterSheet {
    /// Whether this character can be pacified through dialogue.
    ///
    /// Computed based on alignment, intelligence, and charisma. Good and neutral
    /// alignments are more receptive, as are intelligent characters.
    public var canBePacified: Bool {
        // Base pacification from alignment
        var canPacify = alignment.canBePacified

        // Very low intelligence makes pacification harder
        if intelligence <= 6 {
            canPacify = false
        }

        // High charisma characters are more open to dialogue
        if charisma >= 14 {
            canPacify = true
        }

        return canPacify
    }

    /// Health percentage below which fleeing is considered.
    ///
    /// Computed based on bravery and morale. Braver characters fight longer
    /// before considering retreat.
    public var fleeHealthPercent: Int {
        // Base health threshold
        var percent = 30

        // Brave characters fight longer
        percent -= braveryModifier * 3
        percent -= moraleModifier * 2

        // Clamp to 5-50 range
        return max(5, min(50, percent))
    }

    /// Percentage chance (0-100) that the character will flee when badly wounded.
    ///
    /// Computed based on morale, bravery, and alignment. Higher morale and bravery
    /// reduce the chance of fleeing.
    public var fleeThreshold: Int {
        // Base fleeing chance
        var threshold = 20

        // Adjust for morale and bravery
        threshold -= moraleModifier * 5
        threshold -= braveryModifier * 5

        // Alignment affects fleeing
        if alignment.goodEvilAxis == .evil {
            threshold += 10  // Evil characters flee more readily
        }

        // Clamp to 0-100 range
        return max(0, min(100, threshold))
    }

    /// Categorizes a character's overall health state for narrative purposes.
    public var healthCondition: HealthCondition {
        HealthCondition(at: healthPercent)
    }

    /// Difficulty class for pacifying this character through dialogue.
    ///
    /// Computed based on alignment, intelligence, charisma, and intimidation.
    /// Lower values are easier to pacify.
    public var pacifyDC: Int {
        // Base DC from alignment
        var dc = alignment.basePacifyDC

        // Adjust for intelligence (smart characters are easier to reason with)
        dc -= intelligenceModifier

        // Adjust for charisma (charismatic characters appreciate social interaction)
        dc -= charismaModifier

        // Adjust for intimidation (intimidating characters are harder to pacify)
        dc += intimidationModifier

        // Clamp to reasonable range
        return max(5, min(30, dc))
    }

    /// Whether this character requires a weapon to fight effectively.
    ///
    /// Computed based on alignment, armor class, and strength. High AC characters
    /// typically require weapons, while chaotic/evil characters may fight unarmed.
    public var requiresWeapon: Bool {
        // Base requirement from alignment
        var requires = alignment.requiresWeapon

        // High AC characters typically need weapons
        if armorClass >= 15 {
            requires = true
        }

        // Very strong characters might not need weapons
        if strength >= 18 {
            requires = false
        }

        return requires
    }
}

// MARK: - Combat Calculations

extension CharacterSheet {
    /// Base attack bonus derived from level and primary combat attribute.
    ///
    /// Uses the higher of strength (melee) or dexterity (ranged) modifiers.
    public var attackBonus: Int {
        let baseBonus = level + max(strengthModifier, dexterityModifier)
        let conditionModifier = combatCondition.attackModifier
        return baseBonus + conditionModifier
    }

    /// Effective armor class including condition modifiers.
    ///
    /// Based on base armor class modified by current combat condition.
    public var effectiveArmorClass: Int {
        let conditionModifier = combatCondition.armorClassModifier
        return armorClass + conditionModifier
    }

    /// Initiative bonus for determining combat order.
    ///
    /// Based on dexterity, perception, luck, and consciousness level.
    public var initiativeBonus: Int {
        let baseBonus = dexterityModifier + perceptionModifier + (luckModifier / 2)
        let consciousnessModifier = consciousness.initiativeModifier
        return baseBonus + consciousnessModifier
    }

    /// Damage bonus for physical attacks.
    ///
    /// Based primarily on strength, with luck factor.
    public var damageBonus: Int {
        strengthModifier + (luckModifier / 3)
    }

    /// Mental resistance against mind-affecting abilities.
    ///
    /// Based on wisdom, bravery, morale, and general condition.
    public var willSave: Int {
        let baseWill = level + wisdomModifier + (braveryModifier / 2) + (moraleModifier / 2)
        let conditionModifier = generalCondition.abilityCheckModifier
        return baseWill + conditionModifier
    }

    /// Physical toughness against effects.
    ///
    /// Based on constitution, luck, and general condition.
    public var fortitudeSave: Int {
        let baseFortitude = level + constitutionModifier + (luckModifier / 3)
        let conditionModifier = generalCondition.abilityCheckModifier
        return baseFortitude + conditionModifier
    }

    /// Reflexes to avoid area effects.
    ///
    /// Based on dexterity, perception, and general condition.
    public var reflexSave: Int {
        let baseReflex = level + dexterityModifier + (perceptionModifier / 2)
        let conditionModifier = generalCondition.abilityCheckModifier
        return baseReflex + conditionModifier
    }

    /// Bonus to critical hit chance.
    ///
    /// Based on luck and accuracy.
    public var criticalHitBonus: Int {
        luckModifier + (accuracyModifier / 2)
    }

    /// Bonus to surprise attack damage.
    ///
    /// Based on stealth and dexterity.
    public var surpriseAttackBonus: Int {
        stealthModifier + (dexterityModifier / 2)
    }

    /// Effective perception including consciousness and condition modifiers.
    ///
    /// Based on base perception modified by consciousness level and conditions.
    public var effectivePerception: Int {
        let basePerception = perception + perceptionModifier
        let consciousnessModifier = consciousness.perceptionModifier
        let conditionModifier = generalCondition.abilityCheckModifier
        return basePerception + consciousnessModifier + conditionModifier
    }
}

// MARK: - State Queries

extension CharacterSheet {
    /// Whether the character can take actions.
    public var canAct: Bool {
        consciousness.canAct && !generalCondition.impairsFreeWill
    }

    /// Whether the character can perceive their surroundings.
    public var canPerceive: Bool {
        consciousness.canPerceive
    }

    /// Current health as a percentage of maximum health.
    public var healthPercent: Int {
        guard maxHealth > 0 else { return 0 }
        return (health * 100) / maxHealth
    }

    /// Whether the character is awake.
    public var isAwake: Bool {
        switch consciousness {
        case .alert, .drowsy: true
        case .asleep, .unconscious, .coma, .dead: false
        }
    }

    /// Whether the character is badly wounded (below flee threshold).
    public var isBadlyWounded: Bool {
        healthPercent <= fleeHealthPercent
    }

    /// Whether the character is dead.
    public var isDead: Bool {
        consciousness == .dead || health <= 0
    }

    /// Whether the character is impaired in combat.
    public var isImpaired: Bool {
        combatCondition.isDefensivelyImpaired || combatCondition.isOffensivelyImpaired
    }

    /// Whether the character is incapacitated (cannot act).
    public var isIncapacitated: Bool {
        !consciousness.canAct || combatCondition == .surrendered
    }

    /// Whether the character is asleep or unconscious (but not dead).
    public var isUnconscious: Bool {
        switch consciousness {
        case .asleep, .unconscious, .coma: true
        case .alert, .drowsy, .dead: false
        }
    }
}
