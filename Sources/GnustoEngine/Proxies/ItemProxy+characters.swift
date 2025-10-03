import Foundation

// MARK: - Character-Related Accessors

extension ItemProxy {
    /// The character sheet for this item, containing all attributes, combat properties,
    /// and character states.
    ///
    /// For items marked as characters (via CharacterSheet properties), this returns the complete
    /// character sheet including D&D attributes, combat settings, grammatical classification, and
    /// combat states.
    ///
    /// Returns nil for non-character items.
    public var characterSheet: CharacterSheet {
        get async {
            guard let sheet = await property(.characterSheet)?.toCharacterSheet else {
                assertionFailure("ItemProxy.characterSheet called on non-character item")
                return .default
            }
            return sheet
        }
    }

    /// The grammatical classification of this character for pronoun resolution.
    ///
    /// Returns the gender from the character sheet for pronoun and article resolution.
    /// - Throws: `ItemError.notACharacter` if the item doesn't have a character sheet.
    public var classification: Classification {
        get async {
            await characterSheet.classification
        }
    }

    /// The item's current health points.
    ///
    /// Used for combat and other health-related mechanics.
    /// - Throws: `ItemError.notACharacter` if the item doesn't have a character sheet.
    public var health: Int {
        get async {
            await characterSheet.health
        }
    }

    /// Whether this character is currently alive.
    ///
    /// Returns `true` only if the item is a character and is not dead (either by having
    /// the `.isDead` flag set or having health <= 0).
    /// This property is used to determine if a character can perform actions, be interacted with,
    /// or participate in combat.
    public var isAlive: Bool {
        get async {
            guard await isCharacter else { return false }
            return await !characterSheet.isDead
        }
    }

    /// Whether this character is currently awake and conscious.
    ///
    /// Returns `true` only if the item is a character, is not dead, and is not
    /// unconscious. This property is used to determine if a character can perform
    /// conscious actions, respond to interactions, or participate in dialogue.
    public var isAwake: Bool {
        get async {
            guard await isCharacter else { return false }
            return await characterSheet.isAwake
        }
    }

    /// Whether this item represents a character or person.
    ///
    /// Returns `true` if the item has a character sheet defined.
    /// Characters and persons can be talked to, fought, and may have special behaviors.
    public var isCharacter: Bool {
        get async {
            await property(.characterSheet)?.toCharacterSheet != nil
        }
    }

    /// Whether this character is currently dead.
    ///
    /// Returns `true` only if the item is a character and is either marked as dead
    /// in the character sheet or has health <= 0. This property is the inverse of `isAlive`.
    public var isDead: Bool {
        get async {
            guard await isCharacter else { return false }
            return await characterSheet.isDead
        }
    }

    /// Whether this character has been disarmed.
    ///
    /// Returns `true` only if the item is a character and is marked as disarmed
    /// in the character sheet. Disarmed characters fight with reduced effectiveness.
    public var isDisarmed: Bool {
        get async {
            guard await isCharacter else { return false }
            return await characterSheet.combatCondition == .disarmed
        }
    }

    /// Whether this character is currently in a fighting state.
    ///
    /// Returns `true` only if the item is a character and has the fighting flag set.
    /// Fighting characters may attack the player or have different interaction behaviors.
    public var isFighting: Bool {
        get async {
            guard await isCharacter else { return false }
            return await characterSheet.isFighting
        }
    }

    /// Whether this item represents a hostile enemy that's engaged in combat against the player.
    ///
    /// Returns `true` if the item is a character and is awake and actively fighting. Hostile
    /// enemies will attack the player and require different interaction handling.
    public var isHostileEnemy: Bool {
        get async {
            guard await isCharacter else { return false }
            let isAwake = await isAwake
            let isFighting = await isFighting
            let isSurrendered = await isSurrendered
            return isAwake && isFighting && !isSurrendered
        }
    }

    /// Whether this character is off balance and vulnerable.
    ///
    /// Returns `true` only if the item is a character and is marked as off balance
    /// in the character sheet. Off-balance characters have reduced defensive capabilities.
    public var isOffBalance: Bool {
        get async {
            guard await isCharacter else { return false }
            return await characterSheet.combatCondition == .offBalance
        }
    }

    /// Whether this character has surrendered.
    ///
    /// Returns `true` only if the item is a character and has surrendered
    /// according to the character sheet. Surrendered characters cease hostile actions.
    public var isSurrendered: Bool {
        get async {
            guard await isCharacter else { return false }
            return await characterSheet.combatCondition == .surrendered
        }
    }

    /// Whether this character is unconscious.
    ///
    /// Returns `true` only if the item is a character and is marked as unconscious
    /// in the character sheet. Unconscious characters cannot act or defend effectively.
    public var isUnconscious: Bool {
        get async {
            guard await isCharacter else { return false }
            return await characterSheet.isUnconscious
        }
    }

    /// Whether this character is vulnerable to attacks.
    ///
    /// Returns `true` only if the item is a character and is marked as vulnerable
    /// in the character sheet. Vulnerable characters are easier targets for attacks.
    public var isVulnerable: Bool {
        get async {
            guard await isCharacter else { return false }
            return await characterSheet.combatCondition == .vulnerable
        }
    }

    /// The item's maximum health points.
    ///
    /// Uses character properties health if available.
    /// - Throws: `ItemError.notACharacter` if the item doesn't have a character sheet.
    public var maxHealth: Int {
        get async {
            await characterSheet.maxHealth
        }
    }

    /// Selects the best weapon in a character's inventory.
    ///
    /// - Throws: Re-throws any errors from accessing the character's contents or weapon properties.
    public var preferredWeapon: ItemProxy? {
        get async {
            await contents.sortedByWeaponDamage.first
        }
    }

    /// The item's strength for combat and physical actions.
    ///
    /// For character items, this represents physical power and affects combat
    /// effectiveness, carrying capacity, and the success of strength-based actions
    /// like breaking objects or forcing doors. Higher strength values indicate
    /// greater physical capability.
    public var strength: Int {
        get async {
            await characterSheet.strength
        }
    }
}
