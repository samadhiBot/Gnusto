import Foundation

/// Determines visibility and reachability of items and locations based on game state,
/// primarily considering light conditions.
@MainActor // Isolate to MainActor
public struct ScopeResolver: Sendable {

    /// Reference to the GameEngine to access state safely.
    private unowned let engine: GameEngine

    /// Public initializer.
    public init(engine: GameEngine) {
        self.engine = engine
    }

    /// Checks if the specified location is currently lit.
    /// A location is lit if it has the `.inherentlyLit` property, or if the player
    /// (or perhaps an NPC in the same location) is carrying an active light source
    /// (`.lightSource` and `.on` properties).
    ///
    /// - Parameters:
    ///   - locationID: The ID of the location to check.
    /// - Returns: `true` if the location is lit, `false` otherwise.
    public func isLocationLit(locationID: LocationID) -> Bool {
        let gameState = engine.gameState
        guard let location = gameState.locations[locationID] else {
            // Location not found, cannot determine lit status. Defaulting to dark.
            return false
        }

        // 1. Check if the location is inherently lit.
        if location.hasFlag(.inherentlyLit) {
            return true
        }

        // 2. Check if the location has the dynamic .isLit flag set (e.g., by hooks).
        if location.hasFlag(.isLit) {
            return true
        }

        // 3. Check if the player is carrying an active light source.
        let playerInventory = gameState.items.values.filter { $0.parent == .player }
        let playerHasActiveLight = playerInventory.contains { item in
            item.hasFlag(.isLightSource) && item.hasFlag(.isOn)
        }
        if playerHasActiveLight {
            return true
        }

        // 4. Check if there is an active light source directly in the location.
        let itemsInLocation = gameState.items.values.filter { $0.parent == .location(locationID) }
        let locationHasActiveLight = itemsInLocation.contains { item in
            item.hasFlag(.isLightSource) && item.hasFlag(.isOn)
        }
        if locationHasActiveLight {
            return true
        }

        // 5. Otherwise, the location is dark.
        return false
    }

    /// Determines which items are directly visible within a given location.
    /// Considers light conditions and item properties (e.g., `.invisible`).
    /// Does not include contents of containers unless they are transparent.
    ///
    /// - Parameters:
    ///   - locationID: The ID of the location.
    /// - Returns: An array of IDs for items visible in the location.
    public func visibleItemsIn(locationID: LocationID) -> [ItemID] {
        let gameState = engine.gameState
        // 1. Check if the location is lit.
        guard isLocationLit(locationID: locationID) else {
            // If not lit, nothing is visible.
            return []
        }

        // 2. If lit, find items directly in the location.
        let itemsDirectlyInLocation = gameState.items.values.filter { item in
            item.parent == .location(locationID)
        }

        // 3. Filter out items with the .invisible property.
        let visibleItems = itemsDirectlyInLocation.filter { item in
            !item.hasFlag(.isInvisible)
        }

        // 4. Return the IDs of the visible items.
        return visibleItems.map { $0.id }.sorted()
    }

    /// Determines all items currently reachable by the player.
    /// This includes items in their inventory, items visible in the current location,
    /// and the contents of open or transparent containers that are themselves reachable.
    ///
    /// - Returns: A Set of IDs for items reachable by the player.
    public func itemsReachableByPlayer() -> Set<ItemID> {
        let gameState = engine.gameState
        var reachableItems = Set<ItemID>()
        var processedContainers = Set<ItemID>() // Prevent infinite loops with nested containers

        // Add initially reachable items (inventory)
        let inventoryItems = gameState.items.values.filter { $0.parent == .player }
        reachableItems.formUnion(inventoryItems.map { $0.id })

        // Add initially reachable items (visible in location)
        let visibleLocationItems = self.visibleItemsIn(locationID: gameState.player.currentLocationID)
        reachableItems.formUnion(visibleLocationItems)

        // Now, process containers and surfaces among the currently reachable items
        var itemsToCheck = reachableItems // Copy the set to iterate while potentially modifying reachableItems

        while !itemsToCheck.isEmpty {
            let currentItemID = itemsToCheck.removeFirst()
            guard let currentItem = gameState.items[currentItemID] else { continue }

            // A) Check if it's an accessible container
            if currentItem.hasFlag(.isContainer) && !processedContainers.contains(currentItem.id) {
                processedContainers.insert(currentItem.id)
                // Check dynamic property for open state
                let isOpen = engine.gameState.items[currentItem.id]?.attributes[.isOpen]?.toBool ?? false
                let isTransparent = currentItem.hasFlag(.isTransparent)
                if isOpen || isTransparent {
                    // Find items directly inside this container
                    let itemsInside = gameState.items.values.filter { $0.parent == .item(currentItem.id) }
                    let insideIDs = itemsInside.map { $0.id }

                    // Add newly found items to reachable set
                    let newlyReachable = Set(insideIDs).subtracting(reachableItems)
                    reachableItems.formUnion(newlyReachable)

                    // Add newly found items (potential containers/surfaces) to the queue
                    itemsToCheck.formUnion(newlyReachable)
                }
            }

            // B) Check if it's a surface
            if currentItem.hasFlag(.isSurface) {
                // Find items directly on this surface
                let itemsOnSurface = gameState.items.values.filter { $0.parent == .item(currentItem.id) }
                let onSurfaceIDs = itemsOnSurface.map { $0.id }

                // Add newly found items to reachable set
                let newlyReachable = Set(onSurfaceIDs).subtracting(reachableItems)
                reachableItems.formUnion(newlyReachable)

                // Add newly found items (potential containers/surfaces) to the queue
                itemsToCheck.formUnion(newlyReachable)
            }
        }

        return reachableItems
    }

    // Potential recursive helper (alternative implementation strategy)
    // private func getReachableItems(from parent: ParentEntity, processedContainers: inout Set<ItemID>) -> Set<ItemID> { ... }
}
