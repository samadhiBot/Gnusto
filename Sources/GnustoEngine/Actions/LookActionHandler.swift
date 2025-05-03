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
            // Get current location from the snapshot
            let currentLocationID = stateSnapshot.player.currentLocationID
            guard let currentLocation = await engine.location(with: currentLocationID) else {
                // Should not happen if player location is valid
                throw ActionError.internalEngineError("Player is in an invalid location: \(currentLocationID)")
            }

            // Generate description using the new engine method
            let description = await engine.describe(location: currentLocation)

            // Return the description in the ActionResult
            return ActionResult(success: true, message: description)
        }

        // EXAMINE [Object]
        // Validation ensures item exists and is reachable
        guard let targetItem = await engine.item(with: targetItemID) else {
            // This should not happen due to validation, but guard defensively.
            throw ActionError.internalEngineError("Item \(targetItemID) disappeared between validate and process.")
        }

        // 1. Get base description using the new engine method
        var descriptionLines: [String] = []
        let baseDescription = await engine.describe(item: targetItem)
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
        stateSnapshot: GameState // Use snapshot to find items inside/on
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
            if !itemsOnSurface.isEmpty {
                // Use engine helper for formatting
                let itemNames = await engine.listItemsForContents(Array(itemsOnSurface))
                lines.append("On the \(item.name) is \(itemNames).")
            }
            // No message needed if surface is empty
        }
        return lines
    }
}
