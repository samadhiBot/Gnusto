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
}
