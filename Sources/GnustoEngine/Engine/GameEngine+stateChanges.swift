import Foundation

extension GameEngine {
    /// Creates a state change to set a flag on an item if it isn't already set.
    ///
    /// - Parameters:
    ///   - item: The item to set the flag on.
    ///   - attributeID: The flag to set.
    /// - Returns: A `StateChange` to set the flag, or `nil` if the flag is already set.
    public func flag(_ item: Item?, with attributeID: AttributeID) -> StateChange? {
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

    /// Creates a state change to remove a flag from an item if it is currently set.
    ///
    /// - Parameters:
    ///   - item: The item to remove the flag from.
    ///   - attributeID: The flag to remove.
    /// - Returns: A `StateChange` to remove the flag, or `nil` if the flag isn't set.
    public func flag(_ item: Item?, remove attributeID: AttributeID) -> StateChange? {
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

    /// Creates a state change to set a flag on a location if it isn't already set.
    ///
    /// - Parameters:
    ///   - location: The location to set the flag on.
    ///   - attributeID: The flag to set.
    /// - Returns: A `StateChange` to set the flag, or `nil` if the flag is already set.
    public func flag(_ location: Location?, with attributeID: AttributeID) -> StateChange? {
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

    /// Creates a state change to remove a flag from a location if it is currently set.
    ///
    /// - Parameters:
    ///   - location: The location to remove the flag from.
    ///   - attributeID: The flag to remove.
    /// - Returns: A `StateChange` to remove the flag, or `nil` if the flag isn't set.
    public func flag(_ location: Location?, remove attributeID: AttributeID) -> StateChange? {
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

    public func move(_ item: Item, to newParent: ParentEntity) -> StateChange {
        StateChange(
            entityID: .item(item.id),
            attributeKey: .itemParent,
            oldValue: .parentEntity(item.parent),
            newValue: .parentEntity(newParent)
        )
    }

    /// <#Description#>
    /// - Parameter delta: <#delta description#>
    /// - Returns: <#description#>
    public func scoreChange(by delta: Int) -> StateChange {
        StateChange(
            entityID: .player,
            attributeKey: .playerScore,
            oldValue: .int(playerScore),
            newValue: .int(playerScore + delta)
        )
    }

    /// Creates a state change to update the pronoun references for items.
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
