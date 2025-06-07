import Foundation

extension GameState {
    public func hasFlag(_ attributeID: AttributeID, on locationID: LocationID) throws -> Bool {
        guard let location = locations[locationID] else {
            throw GameStateError.locationNotFound(locationID)
        }
        return location.hasFlag(attributeID)
    }

    public func value(
        of attributeID: AttributeID,
        on locationID: LocationID
    ) throws -> Int? {
        guard let location = locations[locationID] else {
            throw GameStateError.locationNotFound(locationID)
        }
        guard let stateValue = location.attributes[attributeID] else {
            return nil
        }
        guard case .int(let value) = stateValue else {
            throw GameStateError.locationAttributeTypeMismatch(locationID, attributeID, actual: stateValue)
        }
        return value
    }

    public func value(
        of attributeID: AttributeID,
        on locationID: LocationID
    ) throws -> String? {
        guard let location = locations[locationID] else {
            throw GameStateError.locationNotFound(locationID)
        }
        guard let stateValue = location.attributes[attributeID] else {
            return nil
        }
        guard case .string(let value) = stateValue else {
            throw GameStateError.locationAttributeTypeMismatch(locationID, attributeID, actual: stateValue)
        }
        return value
    }
}
