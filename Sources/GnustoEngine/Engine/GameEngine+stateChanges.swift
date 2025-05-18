import Foundation

// MARK: - StateChange factories

extension GameEngine {
    /// Creates a `StateChange` to adjust the value of a global integer variable by a given amount.
    ///
    /// This is a factory method for creating a `StateChange` that, when applied,
    /// will modify a numeric global variable. It reads the current value, calculates
    /// the new value, and encapsulates this as a `StateChange`.
    ///
    /// - Parameters:
    ///   - globalID: The `GlobalID` of the integer global variable to adjust.
    ///   - amount: The amount to add to the current value (can be negative to subtract).
    /// - Returns: A `StateChange` object, or `nil` if the global variable identified by
    ///            `globalID` is not currently set or is not an integer.
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


    /// Builds a `StateChange` to remove (clear) a boolean attribute (flag) from an item,
    /// effectively setting it to `false`.
    ///
    /// If the flag is not currently set to `true` on the item, this method returns `nil`
    /// (as no change is needed).
    ///
    /// - Parameters:
    ///   - attributeID: The `AttributeID` of the flag to clear.
    ///   - item: The `Item` instance from which to clear the flag. Pass `nil` if the item
    ///           is not available, though this will result in `nil` being returned.
    /// - Returns: A `StateChange` to clear the flag, or `nil` if the flag is not set or the
    ///            item is `nil`.
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

    /// Builds a `StateChange` to remove (clear) a boolean attribute (flag) from a location,
    /// effectively setting it to `false`.
    ///
    /// If the flag is not currently set to `true` on the location, this method returns `nil`.
    ///
    /// - Parameters:
    ///   - attributeID: The `AttributeID` of the flag to clear.
    ///   - location: The `Location` instance from which to clear the flag. Pass `nil` if the
    ///               location is not available, though this will result in `nil` being returned.
    /// - Returns: A `StateChange` to clear the flag, or `nil` if the flag is not set or the
    ///            location is `nil`.
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

    /// Creates a `StateChange` to move an item to a new parent entity.
    ///
    /// This factory method encapsulates the change of an item's `parentEntity` attribute.
    /// It does not perform validation (e.g., container capacity); that should be done
    /// separately before creating this change or by using `applyItemMove()`.
    ///
    /// - Parameters:
    ///   - item: The `Item` to be moved.
    ///   - newParent: The `ParentEntity` (e.g., a `LocationID`, `.player`, or another `ItemID`
    ///                representing a container) that will be the item's new parent.
    /// - Returns: A `StateChange` object representing the move.
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
    /// (as no change is needed).
    ///
    /// - Parameters:
    ///   - attributeID: The `AttributeID` of the flag to set.
    ///   - item: The `Item` instance on which to set the flag. Pass `nil` if the item is not
    ///           available, though this will result in `nil` being returned.
    /// - Returns: A `StateChange` to set the flag, or `nil` if the flag is already set or
    ///            the item is `nil`.
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

    /// Builds a `StateChange` to set a boolean attribute (flag) on a location to `true`.
    ///
    /// If the flag is already set to `true` on the location, this method returns `nil`.
    ///
    /// - Parameters:
    ///   - attributeID: The `AttributeID` of the flag to set.
    ///   - location: The `Location` instance on which to set the flag. Pass `nil` if the
    ///               location is not available, though this will result in `nil` being returned.
    /// - Returns: A `StateChange` to set the flag, or `nil` if the flag is already set or
    ///            the location is `nil`.
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

    /// Creates a `StateChange` to update the player's score by a given delta.
    ///
    /// This method reads the player's current score from `gameState` and creates a
    /// `StateChange` to adjust it by the specified amount.
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

    /// Builds a `StateChange` to update the game's pronoun references (typically "it" or "them")
    /// to refer to the provided set of items.
    ///
    /// The method determines the correct pronoun ("it" for a single non-plural item,
    /// "them" for multiple items or a single plural item) and creates a `StateChange`
    /// to associate this pronoun with the given items' `EntityReference`s.
    ///
    /// If the pronoun reference would not actually change (i.e., the same pronoun already
    /// refers to the same set of items), this method returns `nil`.
    ///
    /// - Parameter items: A variadic list of `Item` objects that the pronoun should refer to.
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
