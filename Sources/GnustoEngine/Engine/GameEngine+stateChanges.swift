import Foundation

extension GameEngine {
    /// <#Description#>
    /// - Parameters:
    ///   - item: <#item description#>
    ///   - attributeID: <#flag description#>
    /// - Returns: <#description#>
    public func flag(_ item: Item, with attributeID: AttributeID) -> StateChange? {
        if item.attributes[attributeID] == true {
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

    public func flag(_ item: Item, remove attributeID: AttributeID) -> StateChange? {
        if item.attributes[attributeID] != true {
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

    public func flag(_ location: Location, with attributeID: AttributeID) -> StateChange? {
        if location.attributes[attributeID] == true {
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

    public func flag(_ location: Location, remove attributeID: AttributeID) -> StateChange? {
        if location.attributes[attributeID] != true {
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
    /// - Parameter item: <#item description#>
    /// - Returns: <#description#>
    public func updatePronouns(to items: Item...) -> StateChange? {
        let pronoun = switch items.count {
        case 0: "it"
        case 1: items[0].hasFlag(.isPlural) ? "them" : "it"
        default: "them"
        }
        let newItemIDs = Set(items.map(\.id))
        let oldItemIDs = gameState.pronouns[pronoun]
        if newItemIDs == oldItemIDs { return nil }
        return StateChange(
            entityID: .global,
            attributeKey: .pronounReference(pronoun: pronoun),
            oldValue: oldItemIDs.map { .itemIDSet($0) },
            newValue: .itemIDSet(newItemIDs)
        )
    }
}
