import Foundation

// MARK: - Player StateChange factories

extension PlayerProxy {
    /// Creates a `StateChange` to move the player to a specific location.
    ///
    /// - Parameter locationID: The destination location ID.
    /// - Returns: A `StateChange` to move the player to the specified location.
    public func move(to locationID: LocationID) -> StateChange {
        StateChange.movePlayer(to: locationID)
    }

    /// Creates a `StateChange` to move the player to a specified parent entity.
    ///
    /// - Parameter newParent: The destination parent entity.
    /// - Returns: A `StateChange` to move the player to the specified parent.
    public func move(to newParent: ParentEntity) -> StateChange {
        StateChange.movePlayerTo(parent: newParent)
    }

    /// Creates a `StateChange` to update the player's score by a given delta.
    ///
    /// This method reads the player's current score from `gameState` and creates a `StateChange`
    /// to modify it by the specified amount.
    ///
    /// - Parameter delta: The amount to add to the player's current score (can be negative
    ///                  to decrease the score).
    /// - Returns: A `StateChange` object representing the score update.
    public func updateScore(by delta: Int) async -> StateChange {
        StateChange.setPlayerScore(to: player.score + delta)
    }
}

// MARK: - Character-specific state changes

extension PlayerProxy {
    /// Creates a `StateChange` to increase the player's health by the specified amount.
    ///
    /// The health will not exceed the maximum health unless explicitly overridden.
    ///
    /// - Parameters:
    ///   - amount: The amount of healing to apply (positive integer).
    /// - Returns: A `StateChange` to increase health, or `nil` if it wouldn't change.
    public func heal(_ amount: Int) async -> StateChange? {
        let characterSheet = await characterSheet
        let newHealth = min(characterSheet.maxHealth, characterSheet.health + amount)
        guard newHealth != characterSheet.health else { return nil }
        return await setHealth(to: newHealth)
    }

    /// Creates a `StateChange` to set the player's health to a specific value.
    ///
    /// This is a convenience method for directly setting health values.
    ///
    /// - Parameters:
    ///   - health: The new health value.
    /// - Returns: A `StateChange` to set the health, or `nil` if it wouldn't change.
    public func setHealth(to health: Int) async -> StateChange? {
        await setCharacterAttributes(health: health)
    }

    /// Creates a `StateChange` to update multiple character sheet properties at once.
    ///
    /// This method allows you to update any combination of character sheet properties
    /// in a single operation. Only non-nil parameters will be applied to the character sheet.
    ///
    /// - Parameters:
    ///   - strength: The character's physical strength attribute.
    ///   - dexterity: The character's agility and reflexes attribute.
    ///   - constitution: The character's endurance and health attribute.
    ///   - intelligence: The character's reasoning and learning ability.
    ///   - wisdom: The character's awareness and insight attribute.
    ///   - charisma: The character's force of personality and leadership.
    ///   - bravery: The character's courage in dangerous situations.
    ///   - perception: The character's ability to notice details and threats.
    ///   - luck: The character's fortune and chance modifier.
    ///   - morale: The character's current fighting spirit and motivation.
    ///   - accuracy: The character's precision in combat and skill checks.
    ///   - intimidation: The character's ability to frighten or coerce others.
    ///   - stealth: The character's ability to move unseen and unheard.
    ///   - level: The character's experience level or rank.
    ///   - classification: The character's grammatical classification for pronoun usage.
    ///   - alignment: The character's moral and ethical orientation.
    ///   - armorClass: The character's defensive rating against attacks.
    ///   - health: The character's current health points.
    ///   - maxHealth: The character's maximum possible health points.
    ///   - consciousness: The character's current state of awareness.
    ///   - combatCondition: The character's current combat-related status effects.
    ///   - generalCondition: The character's general physical/mental condition.
    ///   - isFighting: Whether the character is currently engaged in combat.
    ///   - weaponWeaknesses: Dictionary of weapon types and damage multipliers for weaknesses.
    ///   - weaponResistances: Dictionary of weapon types and damage reduction for resistances.
    ///   - taunts: Array of phrases the character might use to taunt opponents.
    /// - Returns: A `StateChange` to update the player's character sheet, or `nil` if no changes
    ///            would be made.
    public func setCharacterAttributes(
        strength: Int? = nil,
        dexterity: Int? = nil,
        constitution: Int? = nil,
        intelligence: Int? = nil,
        wisdom: Int? = nil,
        charisma: Int? = nil,
        bravery: Int? = nil,
        perception: Int? = nil,
        luck: Int? = nil,
        morale: Int? = nil,
        accuracy: Int? = nil,
        intimidation: Int? = nil,
        stealth: Int? = nil,
        level: Int? = nil,
        classification: Classification? = nil,
        alignment: Alignment? = nil,
        armorClass: Int? = nil,
        health: Int? = nil,
        maxHealth: Int? = nil,
        consciousness: ConsciousnessLevel? = nil,
        combatCondition: CombatCondition? = nil,
        generalCondition: GeneralCondition? = nil,
        isFighting: Bool? = nil,
        weaponWeaknesses: [ItemID: Int] = [:],
        weaponResistances: [ItemID: Int] = [:],
        taunts: [String] = []
    ) async -> StateChange? {
        var characterSheet = await characterSheet
        var hasChanges = false

        if let strength {
            characterSheet.strength = strength
            hasChanges = true
        }
        if let dexterity {
            characterSheet.dexterity = dexterity
            hasChanges = true
        }
        if let constitution {
            characterSheet.constitution = constitution
            hasChanges = true
        }
        if let intelligence {
            characterSheet.intelligence = intelligence
            hasChanges = true
        }
        if let wisdom {
            characterSheet.wisdom = wisdom
            hasChanges = true
        }
        if let charisma {
            characterSheet.charisma = charisma
            hasChanges = true
        }
        if let bravery {
            characterSheet.bravery = bravery
            hasChanges = true
        }
        if let perception {
            characterSheet.perception = perception
            hasChanges = true
        }
        if let luck {
            characterSheet.luck = luck
            hasChanges = true
        }
        if let morale {
            characterSheet.morale = morale
            hasChanges = true
        }
        if let accuracy {
            characterSheet.accuracy = accuracy
            hasChanges = true
        }
        if let intimidation {
            characterSheet.intimidation = intimidation
            hasChanges = true
        }
        if let stealth {
            characterSheet.stealth = stealth
            hasChanges = true
        }
        if let level {
            characterSheet.level = level
            hasChanges = true
        }
        if let classification {
            characterSheet.classification = classification
            hasChanges = true
        }
        if let alignment {
            characterSheet.alignment = alignment
            hasChanges = true
        }
        if let armorClass {
            characterSheet.armorClass = armorClass
            hasChanges = true
        }
        if let health {
            characterSheet.health = health
            hasChanges = true
        }
        if let maxHealth {
            characterSheet.maxHealth = maxHealth
            hasChanges = true
        }
        if let consciousness {
            characterSheet.consciousness = consciousness
            hasChanges = true
        }
        if let combatCondition {
            characterSheet.combatCondition = combatCondition
            hasChanges = true
        }
        if let generalCondition {
            characterSheet.generalCondition = generalCondition
            hasChanges = true
        }
        if let isFighting {
            characterSheet.isFighting = isFighting
            hasChanges = true
        }

        guard hasChanges else { return nil }

        return .setPlayerAttributes(
            attributes: characterSheet
        )
    }

    /// Creates a `StateChange` to reduce the player's health by the specified amount.
    ///
    /// The health will not go below 0. If the resulting health would be 0 or less,
    /// the character is considered dead.
    ///
    /// - Parameters:
    ///   - amount: The amount of damage to inflict (positive integer).
    /// - Returns: A `StateChange` to reduce health, or `nil` if it wouldn't change.
    public func takeDamage(_ amount: Int) async -> StateChange? {
        let characterSheet = await characterSheet
        let newHealth = max(0, characterSheet.health - amount)
        guard newHealth != characterSheet.health else { return nil }
        return await setHealth(to: newHealth)
    }
}
