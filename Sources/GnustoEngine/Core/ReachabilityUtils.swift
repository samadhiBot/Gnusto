import Foundation

/// Utility functions for determining item reachability and visibility in the game world.
/// This provides shared logic for both synchronous and asynchronous scope resolution.
public struct ReachabilityUtils {

    /// Determines if a container or surface should be recursed into for gathering items.
    /// This is the core logic shared between ScopeResolver and StandardParser.
    ///
    /// - Parameters:
    ///   - item: The item to check (potential container or surface)
    ///   - gameState: Current game state for attribute lookup
    /// - Returns: `true` if the item's contents should be included in scope
    public static func shouldIncludeContents(of item: Item, in gameState: GameState) -> Bool {
        // Surfaces are always accessible
        if item.hasFlag(.isSurface) {
            return true
        }

        // For containers, check if open or transparent
        if item.hasFlag(.isContainer) {
            let isOpen = item.attributes[.isOpen]?.toBool ?? false
            let isTransparent = item.hasFlag(.isTransparent)
            return isOpen || isTransparent
        }

        return false
    }

    /// Gathers all items reachable from a starting parent entity, recursively including
    /// contents of accessible containers and surfaces.
    ///
    /// - Parameters:
    ///   - parentEntity: The starting point (player, location, or item)
    ///   - gameState: Current game state
    ///   - maxDepth: Maximum recursion depth to prevent infinite loops
    ///   - processedContainers: Set to track already processed containers (prevents cycles)
    /// - Returns: Dictionary of reachable items keyed by their ID
    public static func gatherReachableItems(
        from parentEntity: ParentEntity,
        in gameState: GameState,
        maxDepth: Int = 5,
        processedContainers: inout Set<ItemID>
    ) -> [ItemID: Item] {
        var reachableItems: [ItemID: Item] = [:]

        func gatherRecursive(
            from parent: ParentEntity,
            currentDepth: Int = 0
        ) {
            guard currentDepth <= maxDepth else { return }

            // Find items directly in this parent
            let itemsInParent = gameState.items.values.filter { $0.parent == parent }

            for item in itemsInParent {
                reachableItems[item.id] = item

                // Check if we should recurse into this item's contents
                if shouldIncludeContents(of: item, in: gameState) {
                    // For containers, track to prevent infinite recursion
                    if item.hasFlag(.isContainer) {
                        guard !processedContainers.contains(item.id) else { continue }
                        processedContainers.insert(item.id)
                    }

                    gatherRecursive(
                        from: .item(item.id),
                        currentDepth: currentDepth + 1
                    )
                }
            }
        }

        gatherRecursive(from: parentEntity)
        return reachableItems
    }

    /// Determines all items reachable by the player using synchronous game state access.
    /// This is used by the parser for consistent scope resolution.
    ///
    /// - Parameters:
    ///   - gameState: Current game state
    /// - Returns: Dictionary of reachable items keyed by their ID
    public static func itemsReachableByPlayer(in gameState: GameState) -> [ItemID: Item] {
        var processedContainers = Set<ItemID>()
        var allReachableItems: [ItemID: Item] = [:]

        // 1. Gather items from player inventory
        let inventoryItems = gatherReachableItems(
            from: .player,
            in: gameState,
            processedContainers: &processedContainers
        )
        allReachableItems.merge(inventoryItems) { _, new in new }

        // 2. Gather items from current location
        let currentLocationID = gameState.player.currentLocationID
        let locationItems = gatherReachableItems(
            from: .location(currentLocationID),
            in: gameState,
            processedContainers: &processedContainers
        )
        allReachableItems.merge(locationItems) { _, new in new }

        // 3. Add local globals for the current location
        if let location = gameState.locations[currentLocationID] {
            for globalItemID in location.localGlobals {
                if let globalItem = gameState.items[globalItemID],
                   !globalItem.hasFlag(.isInvisible) {
                    allReachableItems[globalItemID] = globalItem
                }
            }
        }

        return allReachableItems
    }

    /// Checks if an item meets basic type and scope conditions for parser object resolution.
    ///
    /// - Parameters:
    ///   - item: The item to check
    ///   - conditions: Required conditions from the parser
    ///   - currentLocationID: The player's current location
    ///   - gameState: Current game state for location lookups
    /// - Returns: `true` if the item meets the specified conditions
    public static func itemMeetsConditions(
        _ item: Item,
        requiredConditions: ObjectCondition,
        currentLocationID: LocationID,
        gameState: GameState
    ) -> Bool {
        let mustBeHeld = requiredConditions.contains(.held)
        let mustBeInRoom = requiredConditions.contains(.inRoom)
        let mustBeOnGround = requiredConditions.contains(.onGround)
        let mustBePerson = requiredConditions.contains(.person)
        let mustBeContainer = requiredConditions.contains(.container)

        // Check type conditions
        if mustBePerson && !item.hasFlag(.isPerson) { return false }
        if mustBeContainer && !item.hasFlag(.isContainer) { return false }

        // Check scope conditions
        if mustBeHeld {
            return item.parent == .player
        } else if mustBeOnGround {
            return item.parent == .location(currentLocationID)
        } else if mustBeInRoom {
            let isGlobal = gameState.locations[currentLocationID]?.localGlobals.contains(item.id) ?? false
            return item.parent == .location(currentLocationID) || isGlobal
        }

        // No specific restrictions - item qualifies if it's reachable
        return true
    }

    /// Filters items based on light conditions. Items are only visible/reachable in lit locations.
    /// This function provides the core light-checking logic that can be used by both
    /// synchronous and asynchronous scope resolvers.
    ///
    /// - Parameters:
    ///   - items: Items to filter
    ///   - locationID: The location to check for lighting
    ///   - gameState: Current game state
    /// - Returns: Items that are accessible given current lighting conditions
    public static func filterByLightConditions(
        _ items: [ItemID: Item],
        in locationID: LocationID,
        gameState: GameState
    ) -> [ItemID: Item] {
        guard isLocationLit(locationID, in: gameState) else {
            return [:]
        }
        return items
    }

    /// Synchronous check for whether a location is lit, using only static game state.
    /// This checks inherent lighting and static light source properties, but cannot
    /// check dynamic attributes that require async access.
    ///
    /// - Parameters:
    ///   - locationID: The location to check
    ///   - gameState: Current game state
    /// - Returns: `true` if the location appears to be lit based on static properties
    public static func isLocationLit(
        _ locationID: LocationID,
        in gameState: GameState
    ) -> Bool {
        guard let location = gameState.locations[locationID] else {
            return false
        }

        // 1. Check if the location is inherently lit
        if location.hasFlag(.inherentlyLit) {
            return true
        }

        // 2. Check if the location has the dynamic .isLit flag set
        if location.hasFlag(.isLit) {
            return true
        }

        // 3. Check if the player is carrying a light source that appears to be on
        // Note: This uses static attributes, not dynamic ones
        let playerInventory = gameState.items.values.filter { $0.parent == .player }
        let playerHasActiveLight = playerInventory.contains { item in
            item.hasFlag(.isLightSource) &&
            (item.hasFlag(.isOn) || (item.attributes[.isOn]?.toBool ?? false))
        }
        if playerHasActiveLight {
            return true
        }

        // 4. Check if there is a light source directly in the location
        let itemsInLocation = gameState.items.values.filter { $0.parent == .location(locationID) }
        let locationHasActiveLight = itemsInLocation.contains { item in
            item.hasFlag(.isLightSource) &&
            (item.hasFlag(.isOn) || (item.attributes[.isOn]?.toBool ?? false))
        }
        if locationHasActiveLight {
            return true
        }

        // 5. Otherwise, assume the location is dark
        return false
    }
}

// MARK: - ObjectCondition Extension

extension ObjectCondition {
    /// Convenience method to check if a condition set contains a specific condition.
    public func contains(_ condition: ObjectCondition) -> Bool {
        return self.intersection(condition) == condition
    }
}
