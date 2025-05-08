import Foundation

extension GameEngine {
    /// <#Description#>
    /// - Parameters:
    ///   - item: <#item description#>
    ///   - flag: <#flag description#>
    /// - Returns: <#description#>
    public func flag(_ item: Item, with flag: AttributeID) -> StateChange? {
        if item.attributes[flag] == true { return nil }
        return StateChange(
            entityID: .item(item.id),
            attributeKey: .itemAttribute(flag),
            oldValue: item.attributes[flag],
            newValue: true,
        )
    }

    public func flag(_ item: Item, remove flag: AttributeID) -> StateChange? {
        if item.attributes[flag] != true { return nil }
        return StateChange(
            entityID: .item(item.id),
            attributeKey: .itemAttribute(flag),
            oldValue: item.attributes[flag],
            newValue: false,
        )
    }

    /// <#Description#>
    /// - Parameter item: <#item description#>
    /// - Returns: <#description#>
    public func pronounStateChange(for items: Item...) -> StateChange? {
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
