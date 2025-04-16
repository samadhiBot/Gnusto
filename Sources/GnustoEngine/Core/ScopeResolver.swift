import Foundation

/// Determines visibility and reachability of items and locations based on game state,
/// primarily considering light conditions.
public struct ScopeResolver: Sendable {

    /// Checks if the specified location is currently lit.
    /// A location is lit if it has the `.inherentlyLit` property, or if the player
    /// (or perhaps an NPC in the same location) is carrying an active light source
    /// (`.lightSource` and `.on` properties).
    ///
    /// - Parameters:
    ///   - locationID: The ID of the location to check.
    ///   - gameState: The current state of the game.
    /// - Returns: `true` if the location is lit, `false` otherwise.
    public func isLocationLit(locationID: Location.ID, gameState: GameState) -> Bool {
        // TODO: Implement light checking logic
        #warning("ScopeResolver.isLocationLit not implemented")
        return true // Placeholder
    }

    /// Determines which items are directly visible within a given location.
    /// Considers light conditions and item properties (e.g., `.invisible`).
    /// Does not include contents of containers unless they are transparent.
    ///
    /// - Parameters:
    ///   - locationID: The ID of the location.
    ///   - gameState: The current state of the game.
    /// - Returns: An array of IDs for items visible in the location.
    public func visibleItemsIn(locationID: Location.ID, gameState: GameState) -> [Item.ID] {
        // TODO: Implement visibility logic
        #warning("ScopeResolver.visibleItemsIn not implemented")
        // Placeholder: Returns all items whose parent is the location
        return gameState.items.values.filter { $0.parent == .location(locationID) }.map { $0.id }
    }

    /// Determines all items currently reachable by the player.
    /// This includes items in their inventory and items visible in the current location
    /// (including contents of open or transparent containers in the location or inventory).
    ///
    /// - Parameter gameState: The current state of the game.
    /// - Returns: An array of IDs for items reachable by the player.
    public func itemsReachableByPlayer(gameState: GameState) -> [Item.ID] {
        // TODO: Implement reachability logic
        #warning("ScopeResolver.itemsReachableByPlayer not implemented")
        // Placeholder: Returns inventory + all items in current room
        let playerLocation = gameState.player.currentLocationID
        let inventoryItems = gameState.items.values.filter { $0.parent == .player }.map { $0.id }
        let locationItems = gameState.items.values.filter { $0.parent == .location(playerLocation) }.map { $0.id }
        return inventoryItems + locationItems
    }
}
