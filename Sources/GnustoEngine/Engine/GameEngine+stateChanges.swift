import Foundation

// MARK: - Global StateChange factories

extension GameEngine {
    /// Creates a `StateChange` to adjust the value of a global integer variable by a given amount.
    ///
    /// This is a factory method for creating a `StateChange` that, when applied,
    /// will modify a numeric global variable. It reads the current value from `gameState`,
    /// calculates the new value, and encapsulates this as a `StateChange`.
    ///
    /// If the global variable doesn't exist yet, it treats the current value as `0`.
    ///
    /// - Parameters:
    ///   - globalID: The `GlobalID` of the integer global variable to adjust.
    ///   - amount: The amount to add to the current value (can be negative to subtract).
    /// - Returns: A `StateChange` object representing the adjustment.
    public func adjustGlobal(_ globalID: GlobalID, by amount: Int) -> StateChange {
        let currentValue: Int = global(globalID) ?? 0
        return StateChange(
            entityID: .global,
            attribute: .globalState(attributeID: globalID),
            oldValue: currentValue == 0 ? nil : .int(currentValue),
            newValue: .int(currentValue + amount)
        )
    }

    public func clearFlag(_ globalID: GlobalID) -> StateChange? {
        return if gameState.globalState[globalID] != true {
            nil
        } else {
            StateChange(
                entityID: .global,
                attribute: .clearFlag(globalID),
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
                attribute: .setFlag(globalID),
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
    /// - `attributeID` is `.pronounReference(pronoun: <determined_pronoun_string>)`
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
            attribute: .pronounReference(pronoun: pronoun),
            oldValue: oldEntityReferences.map { .entityReferenceSet($0) },
            newValue: .entityReferenceSet(newEntityReferences)
        )
    }

    /// Builds `StateChange`s to update both "it" and "them" pronouns for multiple object commands.
    ///
    /// For multiple object commands, we want:
    /// - "it" to refer to the last item processed
    /// - "them" to refer to all the items processed
    ///
    /// This method creates the appropriate state changes for both pronouns.
    ///
    /// - Parameters:
    ///   - lastItem: The last item processed (for "it" pronoun)
    ///   - allItems: All items processed (for "them" pronoun)
    /// - Returns: An array of `StateChange`s to update both pronouns, or empty array if no changes needed.
    public func updatePronounsForMultipleObjects(lastItem: Item, allItems: [Item]) -> [StateChange] {
        var changes: [StateChange] = []
        
        // Update "it" to refer to the last item
        if let itChange = updatePronouns(to: lastItem) {
            changes.append(itChange)
        }
        
        // Update "them" to refer to all items (if more than one)
        if allItems.count > 1 {
            let allEntityReferences = Set(allItems.map { EntityReference.item($0.id) })
            let oldThemReferences = gameState.pronouns["them"]
            
            if allEntityReferences != oldThemReferences {
                let themChange = StateChange(
                    entityID: .global,
                    attribute: .pronounReference(pronoun: "them"),
                    oldValue: oldThemReferences.map { .entityReferenceSet($0) },
                    newValue: .entityReferenceSet(allEntityReferences)
                )
                changes.append(themChange)
            }
        }
        
        return changes
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
        if let item, item.attributes[attributeID] == true {
            setAttribute(attributeID, on: item, to: false)
        } else {
            nil
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
            attribute: .itemParent,
            oldValue: .parentEntity(item.parent),
            newValue: .parentEntity(newParent)
        )
    }

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
    public func setAttribute(
        _ attributeID: AttributeID,
        on item: Item,
        to value: StateValue
    ) -> StateChange? {
        let currentValue = item.attributes[attributeID]
        guard currentValue != value else { return nil }

        return StateChange(
            entityID: .item(item.id),
            attribute: .itemAttribute(attributeID),
            oldValue: currentValue,
            newValue: value
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
        if let item {
            setAttribute(attributeID, on: item, to: true)
        } else {
            nil
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
                attribute: .locationAttribute(attributeID),
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
                attribute: .locationAttribute(attributeID),
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
            attribute: .playerScore,
            oldValue: .int(playerScore),
            newValue: .int(playerScore + delta)
        )
    }
}

// MARK: - Dynamic Attribute StateChange factories

extension GameEngine {

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
    public func setAttribute(
        _ attributeID: AttributeID,
        on location: Location,
        to value: StateValue
    ) -> StateChange? {
        let currentValue = location.attributes[attributeID]
        guard currentValue != value else { return nil }
        
        return StateChange(
            entityID: .location(location.id),
            attribute: .locationAttribute(attributeID),
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
        setAttribute(.description, on: item, to: .string(description))
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
        setAttribute(.description, on: location, to: .string(description))
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
    public func setAttribute(
        _ flag: AttributeID,
        on item: Item,
        to value: Bool
    ) -> StateChange? {
        setAttribute(flag, on: item, to: .bool(value))
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
    public func setAttribute(
        _ flag: AttributeID,
        on location: Location,
        to value: Bool
    ) -> StateChange? {
        setAttribute(flag, on: location, to: .bool(value))
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
    public func setAttribute(
        _ attributeID: AttributeID,
        on item: Item,
        to value: Int
    ) -> StateChange? {
        setAttribute(attributeID, on: item, to: .int(value))
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
    public func setAttribute(
        _ attributeID: AttributeID,
        on location: Location,
        to value: Int
    ) -> StateChange? {
        setAttribute(attributeID, on: location, to: .int(value))
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
    public func setAttribute(
        _ attributeID: AttributeID,
        on item: Item,
        to value: String
    ) -> StateChange? {
        setAttribute(attributeID, on: item, to: .string(value))
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
    public func setAttribute(
        _ attributeID: AttributeID,
        on location: Location,
        to value: String
    ) -> StateChange? {
        setAttribute(attributeID, on: location, to: .string(value))
    }
}
