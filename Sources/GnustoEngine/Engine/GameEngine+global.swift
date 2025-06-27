import Foundation

// MARK: - Global state getters

extension GameEngine {
    /// Retrieves the current set of entity references (usually items) that a specific
    /// pronoun (e.g., "it", "them") refers to.
    ///
    /// - Parameter pronoun: The pronoun string (e.g., "it", "them").
    /// - Returns: A set of `EntityReference` objects, or `nil` if the pronoun is not currently set.
    public func getPronounReference(pronoun: String) -> Set<EntityReference>? {
        gameState.pronouns[pronoun.lowercased()]
    }

    /// Retrieves the boolean value of a global variable from `gameState.globalState`.
    ///
    /// - Parameter bool: The `GlobalID` of the global variable.
    /// - Returns: The boolean value if the global variable exists and is a boolean,
    ///            otherwise `nil`. If the variable exists but is not a boolean type,
    ///            the `toBool` conversion on `StateValue` will determine the result (often `nil`).
    public func global(_ bool: GlobalID) -> Bool? {
        gameState.globalState[bool]?.toBool
    }

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

    /// Retrieves the integer value of a global variable from `gameState.globalState`.
    ///
    /// - Parameter int: The `GlobalID` of the global variable.
    /// - Returns: The integer value if the global variable exists and is an integer,
    ///            otherwise `nil`. If the variable exists but is not an integer type,
    ///            the `toInt` conversion on `StateValue` will determine the result (often `nil`).
    public func global(_ int: GlobalID) -> Int? {
        gameState.globalState[int]?.toInt
    }

    public func global(_ itemRef: GlobalID) -> ItemID? {
        gameState.globalState[itemRef]?.toItemID
    }

    public func global(_ locationRef: GlobalID) -> LocationID? {
        gameState.globalState[locationRef]?.toLocationID
    }

    /// Checks if a boolean flag is set to true in global state.
    ///
    /// This is a convenience method that treats `nil` values as `false`, making it ideal
    /// for checking boolean flags where the absence of the global variable means the flag is not set.
    ///
    /// - Parameter globalID: The `GlobalID` of the boolean global variable to check.
    /// - Returns: `true` if the global variable exists and is `true`, `false` otherwise (including when `nil`).
    public func hasFlag(_ globalID: GlobalID) -> Bool {
        global(globalID) == true
    }

    /// Checks if a global variable exists in the global state.
    ///
    /// - Parameter globalID: The `GlobalID` of the global variable to check.
    /// - Returns: `true` if the global variable exists (regardless of its value), `false` otherwise.
    public func hasGlobal(_ globalID: GlobalID) -> Bool {
        gameState.globalState[globalID] != nil
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
        let oldValue = gameState.globalState[globalID]
        let newValue = StateValue.bool(value)

        return StateChange(
            entityID: .global,
            attribute: .globalState(attributeID: globalID),
            oldValue: oldValue,
            newValue: newValue
        )
    }

    /// Sets a global variable to an integer value.
    ///
    /// - Parameters:
    ///   - globalID: The `GlobalID` of the global variable to set.
    ///   - value: The integer value to set.
    /// - Returns: A `StateChange` representing this modification.
    public func setGlobal(_ globalID: GlobalID, to value: Int) -> StateChange {
        let oldValue = gameState.globalState[globalID]
        let newValue = StateValue.int(value)

        return StateChange(
            entityID: .global,
            attribute: .globalState(attributeID: globalID),
            oldValue: oldValue,
            newValue: newValue
        )
    }

    /// Sets a global variable to an item identifier.
    ///
    /// - Parameters:
    ///   - globalID: The `GlobalID` of the global variable to set.
    ///   - itemID: The item identifier to set.
    /// - Returns: A `StateChange` representing this modification.
    public func setGlobal(_ globalID: GlobalID, to itemID: ItemID) -> StateChange {
        let oldValue = gameState.globalState[globalID]
        let newValue = StateValue.itemID(itemID)

        return StateChange(
            entityID: .global,
            attribute: .globalState(attributeID: globalID),
            oldValue: oldValue,
            newValue: newValue
        )
    }

    /// Sets a global variable to a location identifier.
    ///
    /// - Parameters:
    ///   - globalID: The `GlobalID` of the global variable to set.
    ///   - locationID: The location identifier to set.
    /// - Returns: A `StateChange` representing this modification.
    public func setGlobal(_ globalID: GlobalID, to locationID: LocationID) -> StateChange {
        let oldValue = gameState.globalState[globalID]
        let newValue = StateValue.locationID(locationID)

        return StateChange(
            entityID: .global,
            attribute: .globalState(attributeID: globalID),
            oldValue: oldValue,
            newValue: newValue
        )
    }

    /// Sets a global variable to a string value.
    ///
    /// - Parameters:
    ///   - globalID: The `GlobalID` of the global variable to set.
    ///   - value: The string value to set.
    /// - Returns: A `StateChange` representing this modification.
    public func setGlobal(_ globalID: GlobalID, to value: String) -> StateChange {
        let oldValue = gameState.globalState[globalID]
        let newValue = StateValue.string(value)

        return StateChange(
            entityID: .global,
            attribute: .globalState(attributeID: globalID),
            oldValue: oldValue,
            newValue: newValue
        )
    }

    /// Clears a global variable (removes it from global state).
    ///
    /// - Parameter globalID: The `GlobalID` of the global variable to clear.
    /// - Returns: A `StateChange` representing this modification, or `nil` if the variable doesn't exist.
    public func clearGlobal(_ globalID: GlobalID) -> StateChange? {
        guard let oldValue = gameState.globalState[globalID] else {
            return nil // Variable doesn't exist, nothing to clear
        }

        return StateChange(
            entityID: .global,
            attribute: .globalState(attributeID: globalID),
            oldValue: oldValue,
            newValue: .undefined
        )
    }
}
