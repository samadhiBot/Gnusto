import Foundation

/// Handles the "LOOK" context.command and its synonyms (e.g., "L", "EXAMINE").
public struct LookActionHandler: ActionHandler {
    public func validate(context: ActionContext) async throws {
        // LOOK (no object) always validates
        guard let targetItemID = context.command.directObject else {
            return
        }

        // EXAMINE [Object] - Ensure item exists and is reachable
        guard let _ = await context.engine.item(targetItemID) else {
            // Should not happen if parser resolved correctly, but safety first.
            // Or perhaps the item *just* disappeared.
            throw ActionError.itemNotAccessible(targetItemID)
        }

        // Check reachability using ScopeResolver
        let reachableItems = await context.engine.scopeResolver.itemsReachableByPlayer() // Returns Set<ItemID>
        guard reachableItems.contains(targetItemID) else {
            // Use a standard message even if item technically exists elsewhere
            throw ActionError.itemNotAccessible(targetItemID)
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
                    success: true,
                    message: "It is pitch black. You are likely to be eaten by a grue."
                    // No state changes for looking in the dark
                )
            }

            // 2. Location is lit, proceed with description
            guard let currentLocation = await engine.location(with: currentLocationID) else {
                // Should not happen if player location is valid and not dark
                throw ActionError.internalEngineError(
                    "Player is in an invalid location: \(currentLocationID)"
                )
            }

            // Call helper to print description, passing the snapshot
            await describeLocation(currentLocation, engine: engine, showVerbose: true, stateSnapshot: stateSnapshot)

            // LOOK itself doesn't change state or usually have a message beyond the description printed by the helper.
            // Explicitly initialize the struct.
            return ActionResult(success: true, message: "", stateChanges: [], sideEffects: [])
        }

        // EXAMINE [Object]
        // Validation ensures item exists and is reachable
        guard let targetItem = await engine.item(targetItemID) else {
            // This should not happen due to validation, but guard defensively.
            throw ActionError.internalEngineError(
                "Item \(targetItemID) disappeared between validate and process."
            )
        }

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
        var stateChanges: [StateChange] = []
        if let touchedStateChange = await context.engine.flag(targetItem, with: .isTouched) {
            stateChanges.append(touchedStateChange)
        }

        // 4: Update pronoun
        if let pronounStateChange = await context.engine.pronounStateChange(for: targetItem) {
            stateChanges.append(pronounStateChange)
        }

        // 5. Combine description lines and return result
        let finalMessage = descriptionLines.joined(separator: "\n")
        return ActionResult(
            success: true,
            message: finalMessage,
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
        await listVisibleItems(in: location, engine: engine, showVerbose: showVerbose, stateSnapshot: stateSnapshot)

        // Print obvious exits
        // TODO: Consider visibility/obstructions
        let exits = location.exits
        if !exits.isEmpty {
            let exitStrings = exits.keys.sorted().map { $0.rawValue }
            await engine.ioHandler.print(
                "Obvious exits: \(exitStrings.joined(separator: ", "))",
                style: .normal // Assume .normal exists
            )
        }
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
