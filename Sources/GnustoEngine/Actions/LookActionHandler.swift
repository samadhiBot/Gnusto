import Foundation

/// Handles the "LOOK" context.command and its synonyms (e.g., "L", "EXAMINE").
public struct LookActionHandler: EnhancedActionHandler {

    public init() {}

    // MARK: - EnhancedActionHandler

    public func validate(context: ActionContext) async throws {
        // LOOK (no object) always validates
        guard let targetItemID = context.command.directObject else {
            return
        }

        // EXAMINE [Object] - Ensure item exists and is reachable
        guard let _ = await context.engine.item(with: targetItemID) else {
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
                throw ActionError.internalEngineError("Player is in an invalid location: \(currentLocationID)")
            }

            var descriptionLines: [String] = []

            // 3. Add Title
            descriptionLines.append("--- \(currentLocation.name) ---")

            // 4. Add Location Description (dynamic or default)
            let baseDescription = if let handler = currentLocation.longDescription {
                await engine.descriptionHandlerRegistry.generateDescription(
                    for: currentLocation,
                    using: handler,
                    engine: engine
                )
            } else {
                // Default if location has no longDescription
                "You are in the \(currentLocation.name)."
            }
            descriptionLines.append(baseDescription)

            // 5. Add Visible Items List
            let visibleItemIDs = await engine.scopeResolver.visibleItemsIn(locationID: currentLocationID)
            let visibleItems = visibleItemIDs.compactMap { stateSnapshot.items[$0] } // Get full Item objects from snapshot

            if !visibleItems.isEmpty {
                // Use engine helper to format the list (assuming one exists or creating a temporary one)
                // TODO: Ensure GameEngine has a suitable list formatting helper for location contents
                // For now, using the existing contents helper as a placeholder logic:
                descriptionLines.append(
                    "You can see \(visibleItems.listWithIndefiniteArticles) here."
                )
            }

            // 6. Combine and return
            let finalMessage = descriptionLines.joined(separator: "\n")
            return ActionResult(success: true, message: finalMessage) // No state change for LOOK
        }

        // EXAMINE [Object]
        // Validation ensures item exists and is reachable
        guard let targetItem = await engine.item(with: targetItemID) else {
            // This should not happen due to validation, but guard defensively.
            throw ActionError.internalEngineError("Item \(targetItemID) disappeared between validate and process.")
        }

        // 1. Get base description using the registry
        var descriptionLines: [String] = []
        let baseDescription = if let handler = targetItem.longDescription {
            await engine.descriptionHandlerRegistry.generateDescription(
                for: targetItem,
                using: handler,
                engine: engine
            )
        } else {
            // Default if item has no longDescription
            "You see nothing special about the \(targetItem.name)."
        }
        descriptionLines.append(baseDescription)

        // 2. Add container/surface contents
        // Pass the Item to the helper
        descriptionLines.append(contentsOf: await describeContents(of: targetItem, engine: engine, stateSnapshot: stateSnapshot))

        // 3. Prepare state change (mark as touched)
        var stateChanges: [StateChange] = []
        // Use the item from the snapshot for checking properties
        if let snapshotItem = stateSnapshot.items[targetItemID],
           !snapshotItem.hasProperty(ItemProperty.touched)
        {
            let oldProperties = snapshotItem.properties
            var newProperties = oldProperties
            newProperties.insert(ItemProperty.touched)
            let propertiesChange = StateChange(
                entityId: .item(targetItemID),
                propertyKey: .itemProperties,
                oldValue: .itemPropertySet(oldProperties),
                newValue: .itemPropertySet(newProperties)
            )
            stateChanges.append(propertiesChange)
        }

        // 4. Combine description lines and return result
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

        // Container contents - Check properties on the potentially stale item definition
        if item.hasProperty(.container) {
            // Check current state (open/closed) from the snapshot
            let isOpen = stateSnapshot.items[itemID]?.hasProperty(ItemProperty.open) ?? false
            let isTransparent = item.hasProperty(.transparent) // Transparency is usually static

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

        // Surface contents - Check property on item definition
        if item.hasProperty(.surface) {
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
}
