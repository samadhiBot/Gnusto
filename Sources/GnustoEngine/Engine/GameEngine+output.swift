import Foundation
import OSLog

// MARK: - Output & Error Reporting

extension GameEngine {
    /// Displays the description of the current location, considering light level.
    internal func describeCurrentLocation() async {
        let locationID = gameState.player.currentLocationID

        // 1. Check for light
        let isLitResult = await scopeResolver.isLocationLit(locationID: locationID)
        guard isLitResult else {
            // It's dark!
            await ioHandler.print("It is pitch black. You are likely to be eaten by a grue.")
            // Do not describe the room or list items.
            return
        }

        // 2. If lit, get snapshot and print name
        guard let location = location(with: locationID) else {
            logger.warning("💥 Error: Current location snapshot not found!")
            return
        }
        await ioHandler.print("--- \(location.name) ---", style: .strong)

        // 3. Generate and print the description using the DescriptionHandlerRegistry
        let description = await generateDescription(
            for: location.id,
            key: .description,
            engine: self
        )
        await ioHandler.print(description)

        // 4. List visible items
        await listItemsInLocation(locationID: locationID)
    }

    /// Helper to list items visible in a location (only called if lit).
    private func listItemsInLocation(locationID: LocationID) async {
        // 1. Get visible item IDs using ScopeResolver
        let visibleItemIDs = await scopeResolver.visibleItemsIn(locationID: locationID)

        // 2. Asynchronously fetch Item objects/snapshots for the visible IDs
        let visibleItems = visibleItemIDs.compactMap(item(_:))

        // 3. Format and print the list if not empty
        if !visibleItems.isEmpty {
            // Use the helper to generate a sentence like "a foo, a bar, and a baz"
            let itemListing = visibleItems.listWithIndefiniteArticles
            await ioHandler.print("You can see \(itemListing) here.")
        }
        // No output if no items are visible
    }
}
