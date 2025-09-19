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
