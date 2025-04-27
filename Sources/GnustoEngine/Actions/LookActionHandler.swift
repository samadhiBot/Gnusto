import Foundation

/// Handles the "LOOK" command and its synonyms (e.g., "L", "EXAMINE").
public struct LookActionHandler: EnhancedActionHandler {

    public init() {}

    // MARK: - EnhancedActionHandler

    public func validate(
        command: Command,
        engine: GameEngine
    ) async throws {
        // LOOK (no object) always validates
        guard let targetItemID = command.directObject else {
            return
        }

        // EXAMINE [Object] - Ensure item exists and is reachable
        guard let _ = await engine.itemSnapshot(with: targetItemID) else {
            // Should not happen if parser resolved correctly, but safety first.
            // Or perhaps the item *just* disappeared.
            throw ActionError.itemNotAccessible(targetItemID)
        }

        // Check reachability using ScopeResolver
        let reachableItems = await engine.scopeResolver.itemsReachableByPlayer() // Returns Set<ItemID>
        guard reachableItems.contains(targetItemID) else {
            // Use a standard message even if item technically exists elsewhere
            throw ActionError.itemNotAccessible(targetItemID)
        }
    }

    public func process(
        command: Command,
        engine: GameEngine
    ) async throws -> ActionResult {
        // LOOK (no object)
        guard let targetItemID = command.directObject else {
            // Generate and print the location description directly.
            // Since this bypasses the normal ActionResult message printing,
            // return an empty success result with an empty message.
            // TODO: Refactor describeCurrentLocation to *return* the string
            //       so it fits the ActionResult pattern better.
            await engine.describeCurrentLocation()
            return ActionResult(success: true, message: "") // Message already printed
        }

        // EXAMINE [Object]
        // Validation ensures item exists and is reachable
        guard let targetItem = await engine.itemSnapshot(with: targetItemID) else {
            // This should not happen due to validation, but guard defensively.
            throw ActionError.internalEngineError("Item \(targetItemID) disappeared between validate and process.")
        }

        // 1. Get base description
        var descriptionLines: [String] = []
        if let descriptionHandler = targetItem.longDescription {
            let baseDescription = await engine.descriptionHandlerRegistry.generateDescription(
                for: targetItem,
                using: descriptionHandler,
                engine: engine
            )
            descriptionLines.append(baseDescription)
        } else {
            descriptionLines.append("You see nothing special about the \(targetItem.name).")
        }

        // 2. Add container/surface contents
        // Pass the ItemSnapshot (ReadOnlyItem) to the helper
        descriptionLines.append(contentsOf: await describeContents(of: targetItem, engine: engine))

        // 3. Prepare state change (mark as touched)
        var stateChanges: [StateChange] = []
        if !targetItem.hasProperty(.touched) {
            let oldProperties = targetItem.properties
            var newProperties = oldProperties
            newProperties.insert(.touched)
            let propertiesChange = StateChange(
                objectId: targetItemID,
                propertyKey: .itemProperties,
                oldValue: .itemProperties(oldProperties),
                newValue: .itemProperties(newProperties)
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
    /// Accepts a ItemSnapshot (ReadOnlyItem).
    private func describeContents(of item: ItemSnapshot, engine: GameEngine) async -> [String] {
        var lines: [String] = []

        // Container contents
        if item.hasProperty(.container) {
            let isOpen = item.hasProperty(.open)
            let isTransparent = item.hasProperty(.transparent)

            if isOpen || isTransparent {
                // Get snapshots of items *inside* the container
                let contents = await engine.itemSnapshots(withParent: .item(item.id))
                if contents.isEmpty {
                    lines.append("The \(item.name) is empty.")
                } else {
                    lines.append("The \(item.name) contains:")
                    // TODO: Proper sentence construction with articles/grouping
                    lines.append(contentsOf: contents.map { "  A \($0.name)" }.sorted())
                }
            } else {
                // Closed and not transparent
                lines.append("The \(item.name) is closed.")
            }
        }

        // Surface contents
        if item.hasProperty(.surface) {
            // Get snapshots of items *on* the surface
            let itemsOnSurface = await engine.itemSnapshots(withParent: .item(item.id))
            if !itemsOnSurface.isEmpty {
                lines.append("On the \(item.name) is:")
                // TODO: Proper sentence construction with articles/grouping
                lines.append(contentsOf: itemsOnSurface.map { "  A \($0.name)" }.sorted())
            }
            // No message needed if surface is empty
        }
        return lines
    }
}
