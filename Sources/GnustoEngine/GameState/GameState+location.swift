import Foundation

extension GameState {
    public func hasFlag(_ attributeID: AttributeID, on locationID: LocationID) throws -> Bool {
        guard let location = locations[locationID] else {
            throw GameStateError.locationNotFound(locationID)
        }
        return location.hasFlag(attributeID)
    }

    public func value(
        _ attributeID: AttributeID,
        on locationID: LocationID,
        defaultValue: Int? = 0
    ) throws -> Int {
        guard let location = locations[locationID] else {
            throw GameStateError.locationNotFound(locationID)
        }
        switch location.attributes[attributeID] {
        case .int(let value):
            return value
        case .none:
            if let defaultValue {
                return defaultValue
            } else {
                throw GameStateError.locationAttributeUndefined
            }
        default:
            throw GameStateError.locationAttributeTypeMismatch(locationID, attributeID)
        }
    }

    public func value(
        _ attributeID: AttributeID,
        on locationID: LocationID,
        defaultValue: String? = ""
    ) throws -> String {
        guard let location = locations[locationID] else {
            throw GameStateError.locationNotFound(locationID)
        }
        switch location.attributes[attributeID] {
        case .string(let value):
            return value
        case .none:
            if let defaultValue {
                return defaultValue
            } else {
                throw GameStateError.locationAttributeUndefined
            }
        default:
            throw GameStateError.locationAttributeTypeMismatch(locationID, attributeID)
        }
    }
}
