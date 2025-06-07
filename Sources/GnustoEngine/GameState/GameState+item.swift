import Foundation

extension GameState {
    public func hasFlag(_ attributeID: AttributeID, on itemID: ItemID) throws -> Bool {
        guard let item = items[itemID] else {
            throw GameStateError.itemNotFound(itemID)
        }
        return item.hasFlag(attributeID)
    }

    public func value(
        of attributeID: AttributeID,
        on itemID: ItemID
    ) throws -> Int? {
        guard let item = items[itemID] else {
            throw GameStateError.itemNotFound(itemID)
        }
        guard let stateValue = item.attributes[attributeID] else {
            return nil
        }
        guard case .int(let value) = stateValue else {
            throw GameStateError.itemAttributeTypeMismatch(itemID, attributeID, actual: stateValue)
        }
        return value
    }

    public func value(
        of attributeID: AttributeID,
        on itemID: ItemID
    ) throws -> String? {
        guard let item = items[itemID] else {
            throw GameStateError.itemNotFound(itemID)
        }
        guard let stateValue = item.attributes[attributeID] else {
            return nil
        }
        guard case .string(let value) = stateValue else {
            throw GameStateError.itemAttributeTypeMismatch(itemID, attributeID, actual: stateValue)
        }
        return value
    }
}
