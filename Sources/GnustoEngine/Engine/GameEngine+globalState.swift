import Foundation

// MARK: - Global state getters

extension GameEngine {
    /// <#Description#>
    /// - Parameter bool: <#bool description#>
    /// - Returns: <#description#>
    public func global(_ bool: GlobalID) -> Bool? {
        gameState.globalState[bool]?.toBool
    }

    /// <#Description#>
    /// - Parameter globalID: <#globalID description#>
    /// - Returns: <#description#>
    public func global(_ globalID: GlobalID) -> StateValue? {
        gameState.globalState[globalID]
    }

    /// <#Description#>
    /// - Parameter int: <#int description#>
    /// - Returns: <#description#>
    public func global(_ int: GlobalID) -> Int? {
        gameState.globalState[int]?.toInt
    }
}
