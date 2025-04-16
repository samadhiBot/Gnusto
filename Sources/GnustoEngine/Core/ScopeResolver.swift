import Foundation

/// Determines visibility and reachability of items and locations based on game state,
/// primarily considering light conditions.
public struct ScopeResolver: Sendable {

    /// Public initializer.
    public init() {}

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
        guard let location = gameState.locations[locationID] else {
            // Location not found, cannot determine lit status. Defaulting to dark.
            // Consider logging a warning here if appropriate for the engine's design.
            return false
        }

        // 1. Check if the location is inherently lit.
        if location.hasProperty(.inherentlyLit) {
            return true
        }

        // 2. Check if the player is carrying an active light source.
        let playerInventory = gameState.items.values.filter { $0.parent == .player }
        let playerHasActiveLight = playerInventory.contains { item in
            item.hasProperty(.lightSource) && item.hasProperty(.on)
        }
        if playerHasActiveLight {
            return true
        }

        // 3. Check if there is an active light source directly in the location.
        let itemsInLocation = gameState.items.values.filter { $0.parent == .location(locationID) }
        let locationHasActiveLight = itemsInLocation.contains { item in
            item.hasProperty(.lightSource) && item.hasProperty(.on)
        }
        if locationHasActiveLight {
            return true
        }

        // 4. Otherwise, the location is dark.
        return false
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
        // 1. Check if the location is lit.
        guard isLocationLit(locationID: locationID, gameState: gameState) else {
            // If not lit, nothing is visible.
            return []
        }

        // 2. If lit, find items directly in the location.
        let itemsDirectlyInLocation = gameState.items.values.filter { item in
            item.parent == .location(locationID)
        }

        // 3. Filter out items with the .invisible property.
        let visibleItems = itemsDirectlyInLocation.filter { item in
            !item.hasProperty(.invisible)
        }

        // 4. Return the IDs of the visible items.
        return visibleItems.map { $0.id }
    }

    /// Determines all items currently reachable by the player.
    /// This includes items in their inventory, items visible in the current location,
    /// and the contents of open or transparent containers that are themselves reachable.
    ///
    /// - Parameter gameState: The current state of the game.
    /// - Returns: A Set of IDs for items reachable by the player.
    public func itemsReachableByPlayer(gameState: GameState) -> Set<Item.ID> {
        var reachableItems = Set<Item.ID>()
        // var queue: [ParentEntity] = [.player, .location(gameState.player.currentLocationID)]
        var processedContainers = Set<ItemID>() // Prevent infinite loops with nested containers

        // Add initially reachable items (inventory)
        let inventoryItems = gameState.items.values.filter { $0.parent == .player }
        reachableItems.formUnion(inventoryItems.map { $0.id })

        // Add initially reachable items (visible in location)
        let visibleLocationItems = self.visibleItemsIn(locationID: gameState.player.currentLocationID, gameState: gameState)
        reachableItems.formUnion(visibleLocationItems)

        // Now, process containers among the currently reachable items
        var itemsToCheck = reachableItems // Copy the set to iterate while potentially modifying reachableItems

        while !itemsToCheck.isEmpty {
            let currentItemID = itemsToCheck.removeFirst()
            guard let currentItem = gameState.items[currentItemID] else { continue }

            // Check if it's a container and hasn't been processed yet
            if currentItem.hasProperty(.container) && !processedContainers.contains(currentItem.id) {
                processedContainers.insert(currentItem.id)

                // Check if container is accessible (open or transparent)
                if currentItem.hasProperty(.open) || currentItem.hasProperty(.transparent) {
                    // Find items directly inside this container
                    let itemsInside = gameState.items.values.filter { $0.parent == .item(currentItem.id) }
                    let insideIDs = itemsInside.map { $0.id }

                    // Add newly found items to reachable set
                    let newlyReachable = Set(insideIDs).subtracting(reachableItems)
                    reachableItems.formUnion(newlyReachable)

                    // Add newly found containers to the queue to check their contents
                    itemsToCheck.formUnion(newlyReachable)
                }
            }
        }

        return reachableItems
    }

    // Potential recursive helper (alternative implementation strategy)
    // private func getReachableItems(from parent: ParentEntity, gameState: GameState, processedContainers: inout Set<ItemID>) -> Set<Item.ID> { ... }
}
