import Foundation

// MARK: - Scope Resolution

extension GameEngine {
    /// Determines all items currently reachable by the player.
    ///
    /// This includes items in their inventory, items in scope in the current location, and the
    /// contents of open or transparent containers that are themselves reachable.
    ///
    /// The method performs recursive traversal of containers and surfaces to find all accessible items,
    /// respecting lighting conditions and container accessibility rules.
    ///
    /// - Parameter requiresLight: Whether items in the current location require light to be reachable.
    ///   Inventory items are always reachable regardless of this setting.
    /// - Returns: A set of proxies for items reachable by the player.
    func itemsReachableByPlayer(requiresLight: Bool = true) async -> Set<ItemProxy> {
        let player = await player
        let currentLocation = await player.location

        // Check if the current location is lit - this is critical for reachability
        let isLit = await currentLocation.isLit

        var reachableItems = Set<ItemProxy>()
        var processedContainers = Set<ItemProxy>()

        // 1. Add inventory items (always reachable regardless of lighting)
        let inventoryItems = await player.inventory
        reachableItems.formUnion(inventoryItems)

        // 2. Add items in current location only if lit (or if light is not required)
        if isLit || !requiresLight {
            // Add items directly in the location
            let locationItems = await currentLocation.items
            reachableItems.formUnion(locationItems)

            // Add local globals for the current location
            let scenery = await currentLocation.scenery
            for globalItemID in scenery {
                let globalItem = item(globalItemID)
                let isInvisible = await globalItem.hasFlag(.isInvisible)
                if !isInvisible {
                    reachableItems.insert(globalItem)
                }
            }
        }

        // 3. Process containers and surfaces recursively
        var itemsToCheck = reachableItems

        while itemsToCheck.isNotEmpty {
            let currentItem = itemsToCheck.removeFirst()

            // Check if it's an accessible container
            let isContainer = await currentItem.isContainer
            if isContainer && !processedContainers.contains(currentItem) {
                processedContainers.insert(currentItem)

                let isOpen = await currentItem.hasFlag(.isOpen)
                let isTransparent = await currentItem.hasFlag(.isTransparent)

                if isOpen || isTransparent {
                    let itemsInside = await currentItem.contents
                    let newlyReachable = Set(itemsInside).subtracting(reachableItems)
                    reachableItems.formUnion(newlyReachable)
                    itemsToCheck.formUnion(newlyReachable)
                }
            }

            // Check if it's a non-container (items in non-containers are visible by default)
            else if !(await currentItem.isContainer)
                        && !processedContainers.contains(currentItem)
            {
                processedContainers.insert(currentItem)

                let itemsInside = await currentItem.contents
                let newlyReachable = Set(itemsInside).subtracting(reachableItems)
                reachableItems.formUnion(newlyReachable)
                itemsToCheck.formUnion(newlyReachable)
            }

            // Check if it's a surface
            let isSurface = await currentItem.isSurface
            if isSurface {
                let itemsOnSurface = await currentItem.contents
                let newlyReachable = Set(itemsOnSurface).subtracting(reachableItems)
                reachableItems.formUnion(newlyReachable)
                itemsToCheck.formUnion(newlyReachable)
            }
        }

        return reachableItems
    }

    /// Determines all items currently reachable by the player, requiring light.
    ///
    /// This is a convenience method that calls `itemsReachableByPlayer(requiresLight: true)`.
    /// Items in the player's inventory are always reachable, but items in the current location
    /// require the location to be lit.
    ///
    /// - Returns: A set of proxies for items reachable by the player.
    func itemsReachableByPlayer() async -> Set<ItemProxy> {
        await itemsReachableByPlayer(requiresLight: true)
    }
}
