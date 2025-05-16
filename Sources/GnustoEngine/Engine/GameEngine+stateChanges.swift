import Foundation

// MARK: - StateChange factories

extension GameEngine {
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


    /// Builds a state change to remove a flag from an item if it is currently set.
    ///
    /// - Parameters:
    ///   - attributeID: The flag to remove.
    ///   - item: The item to remove the flag from.
    /// - Returns: A `StateChange` to remove the flag, or `nil` if the flag isn't set.
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

    /// Builds a state change to remove a flag from a location if it is currently set.
    ///
    /// - Parameters:
    ///   - location: The location to remove the flag from.
    ///   - attributeID: The flag to remove.
    /// - Returns: A `StateChange` to remove the flag, or `nil` if the flag isn't set.
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
    
    /// <#Description#>
    /// - Parameters:
    ///   - item: <#item description#>
    ///   - newParent: <#newParent description#>
    /// - Returns: <#description#>
    public func move(_ item: Item, to newParent: ParentEntity) -> StateChange {
        StateChange(
            entityID: .item(item.id),
            attributeKey: .itemParent,
            oldValue: .parentEntity(item.parent),
            newValue: .parentEntity(newParent)
        )
    }

    /// Builds a state change to set a flag on an item if it isn't already set.
    ///
    /// - Parameters:
    ///   - attributeID: The flag to set.
    ///   - item: The item to set the flag on.
    /// - Returns: A `StateChange` to set the flag, or `nil` if the flag is already set.
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

    /// Builds a state change to set a flag on a location if it isn't already set.
    ///
    /// - Parameters:
    ///   - location: The location to set the flag on.
    ///   - attributeID: The flag to set.
    /// - Returns: A `StateChange` to set the flag, or `nil` if the flag is already set.
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

    /// <#Description#>
    /// - Parameter delta: <#delta description#>
    /// - Returns: <#description#>
    public func updatePlayerScore(by delta: Int) -> StateChange {
        StateChange(
            entityID: .player,
            attributeKey: .playerScore,
            oldValue: .int(playerScore),
            newValue: .int(playerScore + delta)
        )
    }

    /// Builds a state change to update the pronoun references for items.
    ///
    /// This method determines the appropriate pronoun ("it" or "them") based on the number and
    /// plurality of the items, and creates a state change to update the global pronoun references.
    ///
    /// - Parameter items: The items to reference with pronouns.
    /// - Returns: A `StateChange` to update the pronoun references, or `nil` if the references
    ///            haven't changed.
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
