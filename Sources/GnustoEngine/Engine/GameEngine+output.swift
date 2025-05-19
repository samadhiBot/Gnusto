import Foundation

// MARK: - Output & Error Reporting

extension GameEngine {
    /// Displays the full description of the player's current location to the player.
    ///
    /// This method performs the following steps:
    /// 1. Checks if the location is lit. If dark, it prints the standard "pitch black" message
    ///    and does not proceed further.
    /// 2. If lit, it prints the location's name.
    /// 3. It generates and prints the location's main description (which may be dynamic).
    /// 4. It lists all items visible to the player in that location.
    ///
    /// This is called by the engine automatically when the player enters a new room, after
    /// certain commands that might change visibility (like turning a light on/off), or when
    /// the player explicitly looks around.
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

    /// Internal helper method to list items visible to the player in a given location.
    ///
    /// This method is only called if the location is determined to be lit.
    /// It uses the `ScopeResolver` to get a list of visible item IDs, fetches their
    /// `Item` data, and then formats them into a sentence like "You can see a foo,
    /// a bar, and a baz here."
    /// If no items are visible, it prints nothing.
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
