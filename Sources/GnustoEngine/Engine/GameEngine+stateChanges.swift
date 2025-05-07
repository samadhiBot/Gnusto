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

    /// <#Description#>
    /// - Parameter item: <#item description#>
    /// - Returns: <#description#>
    public func pronounStateChange(for item: Item) -> StateChange? {
        let pronoun = item.hasFlag(.isPlural) ? "them" : "it"
        let oldValue = gameState.pronouns[pronoun]
        if oldValue == Set([item.id]) { return nil }
        return StateChange(
            entityID: .global,
            attributeKey: .pronounReference(pronoun: "it"),
            oldValue: oldValue.map { .itemIDSet($0) },
            newValue: .itemIDSet([item.id])
        )
    }
}
