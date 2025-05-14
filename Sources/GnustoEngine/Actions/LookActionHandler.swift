import Foundation

/// Handles the "LOOK" context.command and its synonyms (e.g., "L", "EXAMINE").
public struct LookActionHandler: ActionHandler {
    public func validate(context: ActionContext) async throws {
        // LOOK (no direct object) always validates.
        guard let directObjectRef = context.command.directObject else {
            return
        }

        // If a direct object is present, it must be an item for LOOK/EXAMINE.
        guard case .item(let targetItemID) = directObjectRef else {
            // TODO: Consider if LOOK/EXAMINE should support .player or .location directly.
            // For now, only items are supported when a direct object is specified.
            throw ActionResponse.prerequisiteNotMet("You can only look at items this way.")
        }

        // EXAMINE [Item] - Ensure item exists and is reachable
        guard (try? await context.engine.item(targetItemID)) != nil else {
            throw ActionResponse.unknownEntity(directObjectRef) // Was unknownItem
        }

        // Check reachability using ScopeResolver
        guard await context.engine.playerCanReach(targetItemID) else {
            // Use a standard message even if item technically exists elsewhere
            throw ActionResponse.itemNotAccessible(targetItemID)
        }
    }

    public func process(context: ActionContext) async throws -> ActionResult {
        // LOOK (no direct object)
        guard let directObjectRef = context.command.directObject else {
            // 1. Check for darkness FIRST
            guard await context.engine.playerLocationIsLit() else {
                return ActionResult(
                    message: "It is pitch black. You are likely to be eaten by a grue."
                )
            }

            // 2. Location is lit, proceed with description
            await describeLocation(
                try context.engine.playerLocation(),
                engine: context.engine,
                showVerbose: true,
                stateSnapshot: context.stateSnapshot
            )

            // LOOK itself doesn't change state or usually have a message beyond the description
            // printed by the helper.
            return ActionResult()
        }

        // EXAMINE [Object] - directObjectRef is non-nil here.
        // Validate ensures it's an .item, so we can extract targetItemID.
        guard case .item(let targetItemID) = directObjectRef else {
            // This should not be reached if validate is correct.
            throw ActionResponse.internalEngineError("Look: directObject was not an item in process.")
        }

        // Validation ensures item exists and is reachable
        let targetItem = try await context.engine.item(targetItemID)

        var stateChanges: [StateChange] = []

        // 1. Get base description using the registry
        var descriptionLines: [String] = []
        let baseDescription = await context.engine.generateDescription(
            for: targetItem.id, // Use item ID
            key: .description, // Specify the key
            engine: context.engine
        )
        descriptionLines.append(baseDescription)

        // 2. Add container/surface contents
        // Pass the Item to the helper
        descriptionLines.append(
            contentsOf: await describeContents(
                of: targetItem,
                engine: context.engine,
                stateSnapshot: context.stateSnapshot
            )
        )

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
        of item: Item,
        engine: GameEngine,
        stateSnapshot: GameState
    ) async -> [String] {
        var lines: [String] = []
        let itemID = item.id

        // Container contents
        if item.hasFlag(.isContainer) {
            // Check current state (open/closed)
            let isOpen = item.hasFlag(.isOpen)
            let isTransparent = item.hasFlag(.isTransparent)

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
