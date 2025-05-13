import Foundation

/// Handles the "LOOK" context.command and its synonyms (e.g., "L", "EXAMINE").
public struct LookActionHandler: ActionHandler {
    public func validate(context: ActionContext) async throws {
        // LOOK (no object) always validates
        guard let targetItemID = context.command.directObject else {
            return
        }

        // EXAMINE [Object] - Ensure item exists and is reachable
        let _ = try await context.engine.item(targetItemID)

        // Check reachability using ScopeResolver
        guard await context.engine.playerCanReach(targetItemID) else {
            // Use a standard message even if item technically exists elsewhere
            throw ActionResponse.itemNotAccessible(targetItemID)
        }
    }

    public func process(context: ActionContext) async throws -> ActionResult {
        let engine = context.engine
        let stateSnapshot = context.stateSnapshot // Use the snapshot provided by context

        // LOOK (no object)
        guard let targetItemID = context.command.directObject else {
            let currentLocationID = stateSnapshot.player.currentLocationID

            // 1. Check for darkness FIRST
            if await engine.scopeResolver.isLocationLit(locationID: currentLocationID) == false {
                return ActionResult(
                    message: "It is pitch black. You are likely to be eaten by a grue."
                )
            }

            // 2. Location is lit, proceed with description
            let currentLocation = try await engine.playerLocation()

            // Call helper to print description, passing the snapshot
            await describeLocation(
                currentLocation,
                engine: engine,
                showVerbose: true,
                stateSnapshot: stateSnapshot
            )

            // LOOK itself doesn't change state or usually have a message beyond the description
            // printed by the helper.
            return ActionResult()
        }

        // EXAMINE [Object]
        // Validation ensures item exists and is reachable
        let targetItem = try await engine.item(targetItemID)

        var stateChanges: [StateChange] = []

        // 1. Get base description using the registry
        var descriptionLines: [String] = []
        let baseDescription = await engine.generateDescription(
            for: targetItem.id, // Use item ID
            key: .description, // Specify the key
            engine: engine
        )
        descriptionLines.append(baseDescription)

        // 2. Add container/surface contents
        // Pass the Item to the helper
        descriptionLines.append(contentsOf: await describeContents(of: targetItem, engine: engine, stateSnapshot: stateSnapshot))

        // 3. Prepare state change (mark as touched)
        if let update = await context.engine.flag(targetItem, with: .isTouched) {
            stateChanges.append(update)
        }

        // 4: Update pronoun
        if let update = await context.engine.updatePronouns(to: targetItem) {
            stateChanges.append(update)
        }

        // 5. Combine description lines and return result
        return ActionResult(
            message: descriptionLines.joined(separator: "\n"),
            stateChanges: stateChanges
        )
    }

    // Default postProcess will print the message from ActionResult

    // MARK: - Helper Functions

    /// Generates description lines for the contents of a container or surface.
    /// Accepts an Item and uses the GameState snapshot for consistency.
    private func describeContents(
        of item: Item, // The item definition (might be slightly stale if state changed)
        engine: GameEngine, // Needed for helper methods like listWithIndefiniteArticles
        stateSnapshot: GameState // Use snapshot to find current items inside/on
    ) async -> [String] {
        var lines: [String] = []
        let itemID = item.id

        // Container contents - Check flags on the potentially stale item definition
        if item.hasFlag(.isContainer) { // Use flag()
            // Check current state (open/closed) using dynamic value from the snapshot
            let isOpen = stateSnapshot.items[itemID]?.attributes[.isOpen]?.toBool ?? false
            let isTransparent = item.hasFlag(.isTransparent) // Use flag()

            if isOpen || isTransparent {
                // Get items *inside* the container from the snapshot
                let contents = stateSnapshot.items.values.filter { $0.parent == .item(itemID) }
                if contents.isEmpty {
                    lines.append("The \(item.name) is empty.")
                } else {
                    lines.append(
                        // Use engine helper for formatting list
                        "The \(item.name) contains \(contents.listWithIndefiniteArticles)."
                    )
                }
            } else {
                // Closed and not transparent
                lines.append("The \(item.name) is closed.")
            }
        }

        // Surface contents - Check flag on item definition
        if item.hasFlag(.isSurface) { // Use flag()
            // Get items *on* the surface from the snapshot
            let itemsOnSurface = stateSnapshot.items.values.filter { $0.parent == .item(itemID) }
            // Filter out the item itself if it somehow lists itself (e.g., bug)
            let itemsToDescribe = itemsOnSurface.filter { $0.id != itemID }
            if !itemsOnSurface.isEmpty {
                // Use engine helper for formatting
                let isAre = itemsToDescribe.count == 1 ? "is" : "are"
                lines.append(
                    "On the \(item.name) \(isAre) \(itemsToDescribe.listWithIndefiniteArticles)."
                )
            }
            // No message needed if surface is empty
        }
        return lines
    }

    /// Describes the current location in detail.
    private func describeLocation(
        _ location: Location,
        engine: GameEngine,
        showVerbose: Bool,
        stateSnapshot: GameState
    ) async {
        await engine.ioHandler.print("--- \(location.name) ---", style: .strong)

        // Print long description (potentially dynamic)
        let longDesc = await engine.generateDescription(
            for: location.id,
            key: .description,
            engine: engine
        )

        await engine.ioHandler.print(longDesc)

        // List visible items, passing the snapshot
        await listVisibleItems(
            in: location,
            engine: engine,
            showVerbose: showVerbose,
            stateSnapshot: stateSnapshot
        )
    }

    /// Lists items visible in the location.
    private func listVisibleItems(
        in location: Location,
        engine: GameEngine,
        showVerbose: Bool,
        stateSnapshot: GameState // Add stateSnapshot parameter
    ) async {
        // Use the correct ScopeResolver method
        let visibleItemIDs = await engine.scopeResolver.visibleItemsIn(locationID: location.id)

        // Filter out the player if present in scope (shouldn't happen normally)
        let itemIDsToDescribe = visibleItemIDs.filter { $0 != .player }

        guard !itemIDsToDescribe.isEmpty else { return } // Exit if no items to list

        // Original implementation using sentence format: - RESTORE THIS
        let visibleItems = itemIDsToDescribe.compactMap { stateSnapshot.items[$0] }
        if !visibleItems.isEmpty {
            let itemListing = visibleItems.listWithIndefiniteArticles
            await engine.ioHandler.print("You can see \(itemListing) here.")
        }
    }
}
