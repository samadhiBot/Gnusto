import Foundation

extension GameState {
    public func hasFlag(_ globalID: GlobalID) throws -> Bool {
        guard let stateValue = globalState[globalID] else {
            return false
        }
        guard case .bool(let value) = stateValue else {
            throw GameStateError.globalTypeMismatch(globalID, actual: stateValue)
        }
        return value
    }

    public func value(of globalID: GlobalID) throws -> Int? {
        guard let stateValue = globalState[globalID] else {
            return nil
        }
        guard case .int(let value) = stateValue else {
            throw GameStateError.globalTypeMismatch(globalID, actual: stateValue)
        }
        return value
    }

    public func value(of globalID: GlobalID) throws -> String? {
        guard let stateValue = globalState[globalID] else {
            return nil
        }
        guard case .string(let value) = stateValue else {
            throw GameStateError.globalTypeMismatch(globalID, actual: stateValue)
        }
        return value
    }
}
