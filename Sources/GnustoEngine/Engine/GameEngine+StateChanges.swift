import Foundation

// MARK: - Global StateChange factories

extension GameEngine {
    /// Creates a `StateChange` to adjust the value of a global integer variable by a given amount.
    ///
    /// This is a factory method for creating a `StateChange` that, when applied,
    /// will modify a numeric global variable. It reads the current value from `gameState`,
    /// calculates the new value, and encapsulates this as a `StateChange`.
    ///
    /// If the global variable doesn't exist yet, it treats the current value as `0`.
    ///
    /// - Parameters:
    ///   - globalID: The `GlobalID` of the integer global variable to adjust.
    ///   - amount: The amount to add to the current value (can be negative to subtract).
    /// - Returns: A `StateChange` object representing the adjustment.
    public func adjustGlobal(_ globalID: GlobalID, by amount: Int) -> StateChange {
        let currentValue = gameState.globalState[globalID]?.toInt ?? 0
        return StateChange.setGlobalInt(id: globalID, value: currentValue + amount)
    }

    /// Creates a `StateChange` to clear a global flag.
    ///
    /// - Parameter globalID: The `GlobalID` of the flag to clear.
    /// - Returns: A `StateChange` to set the flag to `false`, or `nil` if the flag is not currently `true`.
    public func clearFlag(_ globalID: GlobalID) -> StateChange? {
        if gameState.globalState[globalID] != true {
            nil
        } else {
            StateChange.clearFlag(globalID)
        }
    }

    /// Creates a `StateChange` to update the global combat state to `nil`, thus ending combat.
    ///
    /// - Returns: A `StateChange` object representing the combat state update.
    public func endCombat() -> StateChange {
        setCombatState(to: nil)
    }

    /// Creates a `StateChange` to update the global combat state.
    ///
    /// This factory method creates a `StateChange` that sets the current combat state,
    /// which tracks ongoing combat encounters including participants, intensity, fatigue,
    /// and other combat-related metrics. Setting to `nil` clears the combat state.
    ///
    /// - Parameter combatState: The new `CombatState` to set, or `nil` to clear combat state.
    /// - Returns: A `StateChange` object representing the combat state update.
    public func setCombatState(to combatState: CombatState?) -> StateChange {
        StateChange.setCombatState(combatState)
    }

    /// Creates a `StateChange` to set a global flag.
    ///
    /// - Parameter globalID: The `GlobalID` of the flag to set.
    /// - Returns: A `StateChange` to set the flag to `true`, or `nil` if the flag is already `true`.
    public func setFlag(_ globalID: GlobalID) -> StateChange? {
        if gameState.globalState[globalID] == true {
            nil
        } else {
            StateChange.setFlag(globalID)
        }
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
