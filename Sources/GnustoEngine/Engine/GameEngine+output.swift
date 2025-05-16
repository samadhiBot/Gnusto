import Foundation
import OSLog

// MARK: - Output & Error Reporting

extension GameEngine {
    /// Displays the description of the current location, considering light level.
    func describeCurrentLocation() async throws {
        // 1. Check for light
        guard await playerLocationIsLit() else {
            // It's dark!
            await ioHandler.print("It is pitch black. You are likely to be eaten by a grue.")
            // Do not describe the room or list items.
            return
        }

        // 2. If lit, get snapshot and print name
        let location = try location(playerLocationID)
        await ioHandler.print("--- \(location.name) ---")

        // 3. Generate and print the description using the DescriptionHandlerRegistry
        let description = await generateDescription(
            for: location.id,
            key: .description,
            engine: self
        )
        await ioHandler.print(description)

        // 4. List visible items
        try await listItemsInLocation(locationID: playerLocationID)
    }

    /// Helper to list items visible in a location (only called if lit).
    private func listItemsInLocation(locationID: LocationID) async throws {
        // 1. Get visible item IDs using ScopeResolver
        let visibleItemIDs = await scopeResolver.visibleItemsIn(locationID: locationID)

        // 2. Asynchronously fetch Item objects/snapshots for the visible IDs
        let visibleItems = try visibleItemIDs.compactMap(item(_:))

        // 3. Format and print the list if not empty
        if !visibleItems.isEmpty {
            // Use the helper to generate a sentence like "a foo, a bar, and a baz"
            let itemListing = visibleItems.listWithIndefiniteArticles
            await ioHandler.print("You can see \(itemListing) here.")
        }
        // No output if no items are visible
    }
}
