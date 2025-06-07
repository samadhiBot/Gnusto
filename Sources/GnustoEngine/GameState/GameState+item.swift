import Foundation

extension GameState {
    public func hasFlag(_ attributeID: AttributeID, on itemID: ItemID) throws -> Bool {
        guard let item = items[itemID] else {
            throw GameStateError.itemNotFound(itemID)
        }
        return item.hasFlag(attributeID)
    }

    public func value(
        _ attributeID: AttributeID,
        on itemID: ItemID,
        defaultValue: Int? = 0
    ) throws -> Int {
        guard let item = items[itemID] else {
            throw GameStateError.itemNotFound(itemID)
        }
        switch item.attributes[attributeID] {
        case .int(let value):
            return value
        case .none:
            if let defaultValue {
                return defaultValue
            } else {
                throw GameStateError.itemAttributeUndefined
            }
        default:
            throw GameStateError.itemAttributeTypeMismatch(itemID, attributeID)
        }
    }

    public func value(
        _ attributeID: AttributeID,
        on itemID: ItemID,
        defaultValue: String? = ""
    ) throws -> String {
        guard let item = items[itemID] else {
            throw GameStateError.itemNotFound(itemID)
        }
        switch item.attributes[attributeID] {
        case .string(let value):
            return value
        case .none:
            if let defaultValue {
                return defaultValue
            } else {
                throw GameStateError.itemAttributeUndefined
            }
        default:
            throw GameStateError.itemAttributeTypeMismatch(itemID, attributeID)
        }
    }
}
