import Foundation

// MARK: - Global state getters

extension GameEngine {
    /// Retrieves the raw `StateValue` of a global variable from `gameState.globalState`.
    ///
    /// Use this if you need the untyped `StateValue` or if the type is not simply
    /// boolean or integer.
    ///
    /// - Parameter globalID: The `GlobalID` of the global variable.
    /// - Returns: The `StateValue` if the global variable exists, otherwise `nil`.
    public func global(_ globalID: GlobalID) -> StateValue? {
        gameState.globalState[globalID]
    }

    /// Checks if a boolean flag is set to true in global state.
    ///
    /// This is a convenience method that treats `nil` values as `false`, making it ideal
    /// for checking boolean flags where the absence of the global variable means the flag is not set.
    ///
    /// - Parameter globalID: The `GlobalID` of the boolean global variable to check.
    /// - Returns: `true` if the global variable exists and is `true`, `false` otherwise (including when `nil`).
    public func hasFlag(_ globalID: GlobalID) -> Bool {
        global(globalID)?.toBool == true
    }
    
    /// Whether the player is dead.
    public var isPlayerDead: Bool {
        get async {
            await player.characterSheet.isDead
        }
    }
}

// MARK: - Global state setters

extension GameEngine {
    /// Sets a global variable to a boolean value.
    ///
    /// - Parameters:
    ///   - globalID: The `GlobalID` of the global variable to set.
    ///   - value: The boolean value to set.
    /// - Returns: A `StateChange` representing this modification.
    public func setGlobal(_ globalID: GlobalID, to value: Bool) -> StateChange {
        StateChange.setGlobalBool(id: globalID, value: value)
    }

    /// Sets a global variable to an integer value.
    ///
    /// - Parameters:
    ///   - globalID: The `GlobalID` of the global variable to set.
    ///   - value: The integer value to set.
    /// - Returns: A `StateChange` representing this modification.
    public func setGlobal(_ globalID: GlobalID, to value: Int) -> StateChange {
        StateChange.setGlobalInt(id: globalID, value: value)
    }

    /// Sets a global variable to an item identifier.
    ///
    /// - Parameters:
    ///   - globalID: The `GlobalID` of the global variable to set.
    ///   - itemID: The item identifier to set.
    /// - Returns: A `StateChange` representing this modification.
    public func setGlobal(_ globalID: GlobalID, to itemID: ItemID) -> StateChange {
        StateChange.setGlobalItemID(id: globalID, value: itemID)
    }

    /// Sets a global variable to a location identifier.
    ///
    /// - Parameters:
    ///   - globalID: The `GlobalID` of the global variable to set.
    ///   - locationID: The location identifier to set.
    /// - Returns: A `StateChange` representing this modification.
    public func setGlobal(_ globalID: GlobalID, to locationID: LocationID) -> StateChange {
        StateChange.setGlobalLocationID(id: globalID, value: locationID)
    }

    /// Sets a global variable to a string value.
    ///
    /// - Parameters:
    ///   - globalID: The `GlobalID` of the global variable to set.
    ///   - value: The string value to set.
    /// - Returns: A `StateChange` representing this modification.
    public func setGlobal(_ globalID: GlobalID, to value: String) -> StateChange {
        StateChange.setGlobalString(id: globalID, value: value)
    }

    /// Clears a global variable (removes it from global state).
    ///
    /// - Parameter globalID: The `GlobalID` of the global variable to clear.
    /// - Returns: A `StateChange` representing this modification, or `nil` if the variable doesn't exist.
    public func clearGlobal(_ globalID: GlobalID) -> StateChange? {
        if gameState.globalState[globalID] == nil {
            nil
        } else {
            StateChange.clearGlobalState(id: globalID)
        }
    }
}
