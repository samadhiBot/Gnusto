import Foundation

// MARK: - Global StateChange factories

extension GameEngine {
    /// Creates a `StateChange` to adjust the value of a global integer variable by a given amount.
    ///
    /// This is a factory method for creating a `StateChange` that, when applied,
    /// will modify a numeric global variable. It reads the current value from `gameState`,
    /// calculates the new value, and encapsulates this as a `StateChange`.
    ///
    /// - Parameters:
    ///   - globalID: The `GlobalID` of the integer global variable to adjust.
    ///   - amount: The amount to add to the current value (can be negative to subtract).
    /// - Returns: A `StateChange` object, or `nil` if the global variable identified by
    ///            `globalID` is not currently set or is not an integer in `gameState`.
    public func adjustGlobal(_ globalID: GlobalID, by amount: Int) -> StateChange? {
        if let currentValue: Int = global(globalID) {
            StateChange(
                entityID: .global,
                attributeKey: .globalState(key: globalID),
                oldValue: .int(currentValue),
                newValue: .int(currentValue + amount)
            )
        } else {
            nil
        }
    }

    public func clearFlag(_ globalID: GlobalID) -> StateChange? {
        return if gameState.globalState[globalID] != true {
            nil
        } else {
            StateChange(
                entityID: .global,
                attributeKey: .clearFlag(globalID),
                oldValue: global(globalID),
                newValue: false
            )
        }
    }

    public func setFlag(_ globalID: GlobalID) -> StateChange? {
        if global(globalID) == true {
            return nil
        } else {
            return StateChange(
                entityID: .global,
                attributeKey: .setFlag(globalID),
                oldValue: global(globalID),
                newValue: true,
            )
        }
    }

    /// Builds a `StateChange` to update the game's pronoun references (typically "it" or "them")
    /// to refer to the provided set of items.
    ///
    /// The method determines the appropriate pronoun string ("it" for a single non-plural item,
    /// "them" for multiple items or a single plural item). It then creates a `StateChange` where:
    /// - `attributeKey` is `.pronounReference(pronoun: <determined_pronoun_string>)`
    /// - `newValue` is a `.entityReferenceSet` containing `EntityReference`s for the provided items.
    /// - `oldValue` is the previous set of `EntityReference`s for that pronoun, if any.
    ///
    /// If the pronoun reference would not actually change (i.e., the same pronoun string already
    /// refers to the exact same set of item entities), this method returns `nil`.
    ///
    /// - Parameter items: A variadic list of `Item` objects that the pronoun should now refer to.
    ///                    If empty, "it" will be used and will refer to an empty set.
    /// - Returns: A `StateChange` to update the pronoun reference, or `nil` if no change is needed.
    public func updatePronouns(to items: Item...) -> StateChange? {
        let pronoun = switch items.count {
        case 0: "it"
        case 1: items[0].hasFlag(.isPlural) ? "them" : "it"
        default: "them"
        }
        let newEntityReferences = Set(items.map { EntityReference.item($0.id) })
        let oldEntityReferences = gameState.pronouns[pronoun]

        if newEntityReferences == oldEntityReferences { return nil }

        return StateChange(
            entityID: .global,
            attributeKey: .pronounReference(pronoun: pronoun),
            oldValue: oldEntityReferences.map { .entityReferenceSet($0) },
            newValue: .entityReferenceSet(newEntityReferences)
        )
    }
}

// MARK: - Item StateChange factories

extension GameEngine {
    /// Builds a `StateChange` to clear a boolean attribute (flag) on an item, effectively
    /// setting its value to `false`.
    ///
    /// If the flag is not currently set to `true` on the item (i.e., it's already `false`
    /// or not set), this method returns `nil` as no change is needed.
    ///
    /// - Parameters:
    ///   - attributeID: The `AttributeID` of the flag to clear.
    ///   - item: The `Item` instance from which to clear the flag. If `nil`, this method returns `nil`.
    /// - Returns: A `StateChange` to set the flag to `false`, or `nil` if the flag is not currently
    ///            `true` or the item is `nil`.
    public func clearFlag(_ attributeID: AttributeID, on item: Item?) -> StateChange? {
        guard let item else { return nil }
        return if item.attributes[attributeID] != true {
            nil
        } else {
            StateChange(
                entityID: .item(item.id),
                attributeKey: .itemAttribute(attributeID),
                oldValue: item.attributes[attributeID],
                newValue: false,
            )
        }
    }

    /// Creates a `StateChange` to move an item to a new parent entity.
    ///
    /// This factory method solely creates a `StateChange` to update an item's `.itemParent`
    /// attribute. It does not apply the change to the `GameState`, nor does it perform any
    /// validation (e.g., container capacity checks, reachability) or trigger related side effects.
    /// Such logic is typically handled by higher-level methods in `GameEngine+stateMutation.swift`
    /// or within `ActionHandler` implementations.
    ///
    /// - Parameters:
    ///   - item: The `Item` to be moved.
    ///   - newParent: The `ParentEntity` (e.g., a `LocationID`, `.player`, or another `ItemID`
    ///                representing a container) that will be the item's new parent.
    /// - Returns: A `StateChange` object representing the intended move.
    public func move(_ item: Item, to newParent: ParentEntity) -> StateChange {
        StateChange(
            entityID: .item(item.id),
            attributeKey: .itemParent,
            oldValue: .parentEntity(item.parent),
            newValue: .parentEntity(newParent)
        )
    }

    /// Builds a `StateChange` to set a boolean attribute (flag) on an item to `true`.
    ///
    /// If the flag is already set to `true` on the item, this method returns `nil`
    /// as no change is needed.
    ///
    /// - Parameters:
    ///   - attributeID: The `AttributeID` of the flag to set.
    ///   - item: The `Item` instance on which to set the flag. If `nil`, this method returns `nil`.
    /// - Returns: A `StateChange` to set the flag to `true`, or `nil` if the flag is already
    ///            `true` or the item is `nil`.
    public func setFlag(_ attributeID: AttributeID, on item: Item?) -> StateChange? {
        guard let item else { return nil }
        return if item.attributes[attributeID] == true {
            nil
        } else {
            StateChange(
                entityID: .item(item.id),
                attributeKey: .itemAttribute(attributeID),
                oldValue: item.attributes[attributeID],
                newValue: true,
            )
        }
    }
}

// MARK: - Location StateChange factories

extension GameEngine {
    /// Builds a `StateChange` to clear a boolean attribute (flag) on a location, effectively
    /// setting its value to `false`.
    ///
    /// If the flag is not currently set to `true` on the location (i.e., it's already `false`
    /// or not set), this method returns `nil` as no change is needed.
    ///
    /// - Parameters:
    ///   - attributeID: The `AttributeID` of the flag to clear.
    ///   - location: The `Location` instance from which to clear the flag. If `nil`, this method
    ///               returns `nil`.
    /// - Returns: A `StateChange` to set the flag to `false`, or `nil` if the flag is not currently
    ///            `true` or the location is `nil`.
    public func clearFlag(_ attributeID: AttributeID, on location: Location?) -> StateChange? {
        guard let location else { return nil }
        return if location.attributes[attributeID] != true {
            nil
        } else {
            StateChange(
                entityID: .location(location.id),
                attributeKey: .locationAttribute(attributeID),
                oldValue: location.attributes[attributeID],
                newValue: false,
            )
        }
    }

    /// Builds a `StateChange` to set a boolean attribute (flag) on a location to `true`.
    ///
    /// If the flag is already set to `true` on the location, this method returns `nil`
    /// as no change is needed.
    ///
    /// - Parameters:
    ///   - attributeID: The `AttributeID` of the flag to set.
    ///   - location: The `Location` instance on which to set the flag. If `nil`, this method
    ///               returns `nil`.
    /// - Returns: A `StateChange` to set the flag to `true`, or `nil` if the flag is already
    ///            `true` or the location is `nil`.
    public func setFlag(_ attributeID: AttributeID, on location: Location?) -> StateChange? {
        guard let location else { return nil }
        return if location.attributes[attributeID] == true {
            nil
        } else {
            StateChange(
                entityID: .location(location.id),
                attributeKey: .locationAttribute(attributeID),
                oldValue: location.attributes[attributeID],
                newValue: true,
            )
        }
    }
}

// MARK: - Player StateChange factories

extension GameEngine {
    /// Creates a `StateChange` to update the player's score by a given delta.
    ///
    /// This method reads the player's current score from `gameState` and creates a `StateChange`
    /// to modify it by the specified amount. The `oldValue` in the `StateChange` will be the
    /// score before the delta, and `newValue` will be the score after.
    ///
    /// - Parameter delta: The amount to add to the player's current score (can be negative
    ///                  to decrease the score).
    /// - Returns: A `StateChange` object representing the score update.
    public func updatePlayerScore(by delta: Int) -> StateChange {
        StateChange(
            entityID: .player,
            attributeKey: .playerScore,
            oldValue: .int(playerScore),
            newValue: .int(playerScore + delta)
        )
    }
}

// MARK: - Dynamic Attribute StateChange factories

extension GameEngine {
    /// Creates a `StateChange` to set a dynamic attribute on an item.
    ///
    /// This method creates a `StateChange` that respects the action pipeline and will trigger
    /// dynamic validation handlers when applied. It only creates a change if the new value
    /// differs from the current value.
    ///
    /// - Parameters:
    ///   - attributeID: The `AttributeID` of the attribute to set.
    ///   - item: The `Item` instance to modify.
    ///   - value: The new `StateValue` for the attribute.
    /// - Returns: A `StateChange` to set the attribute, or `nil` if the value wouldn't change.
    public func setItemAttribute(
        _ attributeID: AttributeID,
        on item: Item,
        to value: StateValue
    ) -> StateChange? {
        let currentValue = item.attributes[attributeID]
        guard currentValue != value else { return nil }
        
        return StateChange(
            entityID: .item(item.id),
            attributeKey: .itemAttribute(attributeID),
            oldValue: currentValue,
            newValue: value
        )
    }
    
    /// Creates a `StateChange` to set a dynamic attribute on a location.
    ///
    /// This method creates a `StateChange` that respects the action pipeline and will trigger
    /// dynamic validation handlers when applied. It only creates a change if the new value
    /// differs from the current value.
    ///
    /// - Parameters:
    ///   - attributeID: The `AttributeID` of the attribute to set.
    ///   - location: The `Location` instance to modify.
    ///   - value: The new `StateValue` for the attribute.
    /// - Returns: A `StateChange` to set the attribute, or `nil` if the value wouldn't change.
    public func setLocationAttribute(
        _ attributeID: AttributeID,
        on location: Location,
        to value: StateValue
    ) -> StateChange? {
        let currentValue = location.attributes[attributeID]
        guard currentValue != value else { return nil }
        
        return StateChange(
            entityID: .location(location.id),
            attributeKey: .locationAttribute(attributeID),
            oldValue: currentValue,
            newValue: value
        )
    }
    
    // MARK: - Convenience builders for common dynamic attributes
    
    /// Creates a `StateChange` to set an item's description.
    ///
    /// This is a convenience method for the common pattern of dynamically changing
    /// item descriptions based on game state, similar to ZIL's `PUTP` operations.
    ///
    /// - Parameters:
    ///   - item: The `Item` instance to modify.
    ///   - description: The new description text.
    /// - Returns: A `StateChange` to set the description, or `nil` if it wouldn't change.
    public func setDescription(on item: Item, to description: String) -> StateChange? {
        setItemAttribute(.description, on: item, to: .string(description))
    }
    
    /// Creates a `StateChange` to set a location's description.
    ///
    /// This is a convenience method for the common pattern of dynamically changing
    /// location descriptions based on game state, similar to ZIL's `PUTP` operations.
    ///
    /// - Parameters:
    ///   - location: The `Location` instance to modify.
    ///   - description: The new description text.
    /// - Returns: A `StateChange` to set the description, or `nil` if it wouldn't change.
    public func setDescription(on location: Location, to description: String) -> StateChange? {
        setLocationAttribute(.description, on: location, to: .string(description))
    }
    
    /// Creates a `StateChange` to set a boolean flag attribute on an item.
    ///
    /// This is a convenience method for the common pattern of setting boolean flags,
    /// similar to ZIL's `FSET` and `FCLEAR` operations, but for dynamic attributes.
    ///
    /// - Parameters:
    ///   - flag: The name of the flag attribute to set.
    ///   - item: The `Item` instance to modify.
    ///   - value: The boolean value to set (`true` to set the flag, `false` to clear it).
    /// - Returns: A `StateChange` to set the flag, or `nil` if it wouldn't change.
    public func setItemFlag(
        _ flag: String,
        on item: Item,
        to value: Bool
    ) -> StateChange? {
        setItemAttribute(AttributeID(flag), on: item, to: .bool(value))
    }
    
    /// Creates a `StateChange` to set a boolean flag attribute on a location.
    ///
    /// This is a convenience method for the common pattern of setting boolean flags on locations,
    /// similar to ZIL's `FSET` and `FCLEAR` operations, but for dynamic attributes.
    ///
    /// - Parameters:
    ///   - flag: The name of the flag attribute to set.
    ///   - location: The `Location` instance to modify.
    ///   - value: The boolean value to set (`true` to set the flag, `false` to clear it).
    /// - Returns: A `StateChange` to set the flag, or `nil` if it wouldn't change.
    public func setLocationFlag(
        _ flag: String,
        on location: Location,
        to value: Bool
    ) -> StateChange? {
        setLocationAttribute(AttributeID(flag), on: location, to: .bool(value))
    }
    
    /// Creates a `StateChange` to set an integer attribute on an item.
    ///
    /// This is a convenience method for setting numeric attributes on items.
    ///
    /// - Parameters:
    ///   - attributeID: The `AttributeID` of the attribute to set.
    ///   - item: The `Item` instance to modify.
    ///   - value: The integer value to set.
    /// - Returns: A `StateChange` to set the attribute, or `nil` if it wouldn't change.
    public func setItemInt(
        _ attributeID: AttributeID,
        on item: Item,
        to value: Int
    ) -> StateChange? {
        setItemAttribute(attributeID, on: item, to: .int(value))
    }
    
    /// Creates a `StateChange` to set an integer attribute on a location.
    ///
    /// This is a convenience method for setting numeric attributes on locations.
    ///
    /// - Parameters:
    ///   - attributeID: The `AttributeID` of the attribute to set.
    ///   - location: The `Location` instance to modify.
    ///   - value: The integer value to set.
    /// - Returns: A `StateChange` to set the attribute, or `nil` if it wouldn't change.
    public func setLocationInt(
        _ attributeID: AttributeID,
        on location: Location,
        to value: Int
    ) -> StateChange? {
        setLocationAttribute(attributeID, on: location, to: .int(value))
    }
    
    /// Creates a `StateChange` to set a string attribute on an item.
    ///
    /// This is a convenience method for setting string attributes on items.
    ///
    /// - Parameters:
    ///   - attributeID: The `AttributeID` of the attribute to set.
    ///   - item: The `Item` instance to modify.
    ///   - value: The string value to set.
    /// - Returns: A `StateChange` to set the attribute, or `nil` if it wouldn't change.
    public func setItemString(
        _ attributeID: AttributeID,
        on item: Item,
        to value: String
    ) -> StateChange? {
        setItemAttribute(attributeID, on: item, to: .string(value))
    }
    
    /// Creates a `StateChange` to set a string attribute on a location.
    ///
    /// This is a convenience method for setting string attributes on locations.
    ///
    /// - Parameters:
    ///   - attributeID: The `AttributeID` of the attribute to set.
    ///   - location: The `Location` instance to modify.
    ///   - value: The string value to set.
    /// - Returns: A `StateChange` to set the attribute, or `nil` if it wouldn't change.
    public func setLocationString(
        _ attributeID: AttributeID,
        on location: Location,
        to value: String
    ) -> StateChange? {
        setLocationAttribute(attributeID, on: location, to: .string(value))
    }
}
