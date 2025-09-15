import Foundation

// MARK: - Item StateChange factories

extension ItemProxy {
    /// Builds a `StateChange` to clear a boolean property (flag) on an item.
    ///
    /// If the flag is not currently set to `true` on the item (i.e., it's already `false`
    /// or not set), this method returns `nil` as no change is needed.
    ///
    /// - Parameters:
    ///   - propertyID: The `PropertyID` of the flag to clear.
    /// - Returns: A `StateChange` to set the flag to `false`, or `nil` if the flag is not currently
    ///            `true`.
    public func clearFlag(_ propertyID: ItemPropertyID) async throws -> StateChange? {
        if try await property(propertyID)?.toBool == true {
            try await setProperty(propertyID, to: false)
        } else {
            nil
        }
    }

    /// Creates a `StateChange` to move an item to a new parent entity.
    ///
    /// This factory method solely creates a `StateChange` to update an item's parent.
    /// It does not apply the change to the `GameState`, nor does it perform any
    /// validation (e.g., container capacity checks, reachability) or trigger related side effects.
    /// Such logic is typically handled by higher-level methods or within `ActionHandler` implementations.
    ///
    /// - Parameters:
    ///   - newParent: The `ParentEntity` (e.g., a `LocationID`, `.player`, or another `ItemID`
    ///                representing a container) that will be the item's new parent.
    /// - Returns: A `StateChange` object representing the intended move.
    public func move(to newParent: ParentEntity) -> StateChange {
        StateChange.moveItem(id: id, to: newParent)
    }

    /// Creates a `StateChange` to move an item to another item (container).
    ///
    /// This is a convenience method that wraps the main `move(to:)` method for moving
    /// items into containers represented by other items.
    ///
    /// - Parameters:
    ///   - itemID: The `ItemID` of the container item that will be the new parent.
    /// - Returns: A `StateChange` object representing the intended move.
    public func move(to itemID: ItemID) -> StateChange {
        move(to: .item(itemID))
    }

    /// Creates a `StateChange` to move an item to a location.
    ///
    /// This is a convenience method that wraps the main `move(to:)` method for moving
    /// items to locations.
    ///
    /// - Parameters:
    ///   - locationID: The `LocationID` of the location that will be the new parent.
    /// - Returns: A `StateChange` object representing the intended move.
    public func move(to locationID: LocationID) -> StateChange {
        move(to: .location(locationID))
    }

    /// Creates a `StateChange` to remove an item from the game (move to `.nowhere`).
    ///
    /// - Returns: A `StateChange` object representing the removal.
    public func remove() -> StateChange {
        move(to: .nowhere)
    }

    /// Creates a `StateChange` to set a dynamic property on an item.
    ///
    /// This method creates a `StateChange` that respects the action pipeline and will trigger
    /// dynamic validation handlers when applied. It only creates a change if the new value
    /// differs from the current value.
    ///
    /// - Parameters:
    ///   - propertyID: The `PropertyID` of the property to set.
    ///   - value: The new `StateValue` for the property.
    /// - Returns: A `StateChange` to set the property, or `nil` if the value wouldn't change.
    public func setProperty(
        _ propertyID: ItemPropertyID,
        to value: StateValue
    ) async throws -> StateChange? {
        let currentValue = try await property(propertyID)
        guard currentValue != value else { return nil }

        return StateChange.setItemProperty(id: id, property: propertyID, value: value)
    }

    /// Builds a `StateChange` to set a boolean property (flag) on an item to `true`.
    ///
    /// If the flag is already set to `true` on the item, this method returns `nil`
    /// as no change is needed.
    ///
    /// - Parameters:
    ///   - propertyID: The `PropertyID` of the flag to set.
    /// - Returns: A `StateChange` to set the flag to `true`, or `nil` if the flag is already
    ///            `true`.
    public func setFlag(_ propertyID: ItemPropertyID) async throws -> StateChange? {
        if try await property(propertyID)?.toBool == true {
            nil
        } else {
            try await setProperty(propertyID, to: true)
        }
    }
}

// MARK: - Convenience builders for common dynamic properties

extension ItemProxy {
    /// Creates a `StateChange` to set an item's description.
    ///
    /// This is a convenience method for the common pattern of dynamically changing
    /// item descriptions based on game state, similar to ZIL's `PUTP` operations.
    ///
    /// - Parameters:
    ///   - description: The new description text.
    /// - Returns: A `StateChange` to set the description, or `nil` if it wouldn't change.
    public func setDescription(to description: String) async throws -> StateChange? {
        try await setProperty(.description, to: .string(description))
    }

    /// Creates a `StateChange` to set a boolean flag property on an item.
    ///
    /// This is a convenience method for the common pattern of setting boolean flags,
    /// similar to ZIL's `FSET` and `FCLEAR` operations, but for dynamic properties.
    ///
    /// - Parameters:
    ///   - flag: The name of the flag property to set.
    ///   - value: The boolean value to set (`true` to set the flag, `false` to clear it).
    /// - Returns: A `StateChange` to set the flag, or `nil` if it wouldn't change.
    public func setProperty(
        _ flag: ItemPropertyID,
        to value: Bool
    ) async throws -> StateChange? {
        try await setProperty(flag, to: .bool(value))
    }

    /// Creates a `StateChange` to set an integer property on an item.
    ///
    /// This is a convenience method for setting numeric properties on items.
    ///
    /// - Parameters:
    ///   - propertyID: The `PropertyID` of the property to set.
    ///   - value: The integer value to set.
    /// - Returns: A `StateChange` to set the property, or `nil` if it wouldn't change.
    public func setProperty(
        _ propertyID: ItemPropertyID,
        to value: Int
    ) async throws -> StateChange? {
        try await setProperty(propertyID, to: .int(value))
    }

    /// Creates a `StateChange` to set a string property on an item.
    ///
    /// This is a convenience method for setting string properties on items.
    ///
    /// - Parameters:
    ///   - propertyID: The `PropertyID` of the property to set.
    ///   - value: The string value to set.
    /// - Returns: A `StateChange` to set the property, or `nil` if it wouldn't change.
    public func setProperty(
        _ propertyID: ItemPropertyID,
        to value: String
    ) async throws -> StateChange? {
        try await setProperty(propertyID, to: .string(value))
    }
}

// MARK: - Character-specific state changes

extension ItemProxy {
    /// Creates a `StateChange` to update multiple character sheet properties at once.
    ///
    /// This method allows you to update any combination of character sheet properties
    /// in a single operation. Only non-nil parameters will be applied to the character sheet.
    /// If the item is not a character (doesn't have a character sheet), this method
    /// throws an error.
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
    /// - Returns: A `StateChange` to update the character sheet, or `nil` if no changes
    ///            would be made.
    /// - Throws: `ItemError.notACharacter` if the item doesn't have a character sheet.
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
    ) async throws -> StateChange? {
        var characterSheet = try await characterSheet
        if let strength {
            characterSheet.strength = strength
        }
        if let dexterity {
            characterSheet.dexterity = dexterity
        }
        if let constitution {
            characterSheet.constitution = constitution
        }
        if let intelligence {
            characterSheet.intelligence = intelligence
        }
        if let wisdom {
            characterSheet.wisdom = wisdom
        }
        if let charisma {
            characterSheet.charisma = charisma
        }
        if let bravery {
            characterSheet.bravery = bravery
        }
        if let perception {
            characterSheet.perception = perception
        }
        if let luck {
            characterSheet.luck = luck
        }
        if let morale {
            characterSheet.morale = morale
        }
        if let accuracy {
            characterSheet.accuracy = accuracy
        }
        if let intimidation {
            characterSheet.intimidation = intimidation
        }
        if let stealth {
            characterSheet.stealth = stealth
        }
        if let level {
            characterSheet.level = level
        }
        if let classification {
            characterSheet.classification = classification
        }
        if let alignment {
            characterSheet.alignment = alignment
        }
        if let armorClass {
            characterSheet.armorClass = armorClass
        }
        if let health {
            characterSheet.health = health
        }
        if let maxHealth {
            characterSheet.maxHealth = maxHealth
        }
        if let consciousness {
            characterSheet.consciousness = consciousness
        }
        if let combatCondition {
            characterSheet.combatCondition = combatCondition
        }
        if let generalCondition {
            characterSheet.generalCondition = generalCondition
        }
        if let isFighting {
            characterSheet.isFighting = isFighting
        }
        return try await setProperty(
            .characterSheet,
            to: .characterSheet(characterSheet)
        )
    }
}

// MARK: - Health-specific convenience methods

extension ItemProxy {
    /// Creates a `StateChange` to reduce a character's health by the specified amount.
    ///
    /// The health will not go below zero. At zero a character is considered dead.
    ///
    /// - Parameters:
    ///   - amount: The amount of damage to inflict (positive integer).
    /// - Returns: A `StateChange` to reduce health, or `nil` if it wouldn't change.
    public func takeDamage(_ amount: Int) async throws -> StateChange? {
        var characterSheet = try await characterSheet
        characterSheet.health = max(0, characterSheet.health - amount)
        return try await setProperty(
            .characterSheet,
            to: .characterSheet(characterSheet)
        )
    }

    /// Creates a `StateChange` to increase a character's health by the specified amount.
    ///
    /// The health will not exceed the item's maximum health.
    ///
    /// - Parameters:
    ///   - amount: The amount of healing to apply (positive integer).
    /// - Returns: A `StateChange` to increase health, or `nil` if it wouldn't change.
    public func heal(_ amount: Int) async throws -> StateChange? {
        var characterSheet = try await characterSheet
        characterSheet.health = min(
            characterSheet.maxHealth,
            characterSheet.health + amount
        )
        return try await setProperty(
            .characterSheet,
            to: .characterSheet(characterSheet)
        )
    }

    /// Creates a `StateChange` to set a character's health to a specific value.
    ///
    /// This is a convenience method for directly setting health values. Unlike `heal`,
    /// this method does allow `health` to exceed the character's `maxHealth`.
    ///
    /// - Parameters:
    ///   - health: The new health value.
    /// - Returns: A `StateChange` to set the health, or `nil` if it wouldn't change.
    public func setHealth(to health: Int) async throws -> StateChange? {
        var characterSheet = try await characterSheet
        characterSheet.health = health
        return try await setProperty(
            .characterSheet,
            to: .characterSheet(characterSheet)
        )
    }
}
