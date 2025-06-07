import Foundation

extension GameState {
    public func attribute(
        _ attributeID: AttributeID,
        of itemID: ItemID
    ) throws -> Bool? {
        guard let value = try fetchStateValue(
            itemID: itemID,
            attributeID: attributeID
        ) else {
            return nil
        }
        guard case .bool(let bool) = value else {
            throw GameStateError.itemAttributeTypeMismatch(itemID, attributeID, actual: value)
        }
        return bool
    }

    public func attribute(
        _ attributeID: AttributeID,
        of itemID: ItemID
    ) throws -> Int? {
        guard let value = try fetchStateValue(
            itemID: itemID,
            attributeID: attributeID
        ) else {
            return nil
        }
        guard case .int(let integer) = value else {
            throw GameStateError.itemAttributeTypeMismatch(itemID, attributeID, actual: value)
        }
        return integer
    }

    public func attribute(
        _ attributeID: AttributeID,
        of itemID: ItemID
    ) throws -> String? {
        guard let value = try fetchStateValue(
            itemID: itemID,
            attributeID: attributeID
        ) else {
            return nil
        }
        guard case .string(let string) = value else {
            throw GameStateError.itemAttributeTypeMismatch(itemID, attributeID, actual: value)
        }
        return string
    }

    public func generateDescription(
        _ attributeID: AttributeID,
        for itemID: ItemID,
    ) throws -> String {
        if let description: String = try attribute(attributeID, of: itemID) {
            description.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            try defaultItemDescription(
                for: itemID,
                attributeID: attributeID
            ).trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    public func hasFlag(
        _ attributeID: AttributeID,
        on itemID: ItemID
    ) throws -> Bool {
        (try attribute(attributeID, of: itemID)) == true
    }

    public func item(_ itemID: ItemID) throws -> Item {
        guard let item = items[itemID] else {
            throw GameStateError.itemNotFound(itemID)
        }
        return item
    }

    public func items(in parent: ParentEntity) -> [Item] {
        items.values.filter { $0.parent == parent }
    }
}

// MARK: - Private helpers

extension GameState {
    private func defaultItemDescription(
        for itemID: ItemID,
        attributeID: AttributeID
    ) throws -> String {
        let item = try item(itemID)
        return switch attributeID {
        case .description:
            "You see nothing special about \(item.withDefiniteArticle)."
        case .shortDescription:
            "\(item.withIndefiniteArticle.capitalizedFirst)."
        case .firstDescription:
            "There is \(item.withIndefiniteArticle) here."
        case .readText:
            "There is nothing written on \(item.withDefiniteArticle)."
        case .readWhileHeldText:
            "Holding \(item.withDefiniteArticle) reveals nothing special."
        default:
            "\(item.withDefiniteArticle.capitalizedFirst) seems indescribable."
        }
    }

    private func fetchStateValue(
        itemID: ItemID,
        attributeID: AttributeID
    ) throws -> StateValue? {
        try item(itemID).attributes[attributeID]
    }
}
