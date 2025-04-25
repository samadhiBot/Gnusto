import Foundation

/// Handles the "LOOK" command and its synonyms (e.g., "L", "EXAMINE").
public struct LookActionHandler: ActionHandler {

    public init() {}

    public func perform(command: Command, engine: GameEngine) async throws {
        // LOOK (no object) - Describe the current location
        if command.directObject == nil {
            await engine.describeCurrentLocation()
            return
        }

        // LOOK AT/EXAMINE [Object]
        guard let targetItemID = command.directObject else {
            // Should have been handled by the case above, but safety first
            throw ActionError.internalEngineError("LOOK command parsed without direct object, but wasn't caught earlier.")
        }

        // Use safe snapshot accessor
        guard let targetItemSnapshot = await engine.itemSnapshot(with: targetItemID) else {
            // Should not happen if parser resolved correctly
            throw ActionError.internalEngineError("Resolved item ID \(targetItemID) not found in game state.")
        }

        // Get the item's description using the description handler
        if let descriptionHandler = targetItemSnapshot.description {
            let description = await engine.descriptionHandlerRegistry.generateDescription(
                for: targetItemSnapshot,
                using: descriptionHandler,
                engine: engine
            )
            await engine.ioHandler.print(description)
        } else {
            // Default message if no description handler
            await engine.ioHandler.print("You see nothing special about the \(targetItemSnapshot.name).")
        }

        // If the item is a container, list its *visible* contents
        if targetItemSnapshot.hasProperty(.container) {
            let isOpen = targetItemSnapshot.hasProperty(.open)
            let isTransparent = targetItemSnapshot.hasProperty(.transparent)

            if isOpen || isTransparent {
                let contents = await engine.itemSnapshots(withParent: .item(targetItemSnapshot.id))
                if contents.isEmpty {
                    await engine.ioHandler.print("The \(targetItemSnapshot.name) is empty.")
                } else {
                    await engine.ioHandler.print("The \(targetItemSnapshot.name) contains:")
                    for item in contents {
                        // TODO: Proper sentence construction with articles
                        await engine.ioHandler.print("  A \(item.name)")
                    }
                }
            } else {
                // Closed and not transparent
                await engine.ioHandler.print("The \(targetItemSnapshot.name) is closed.")
            }
        }

        // If the item is a surface, list items on it
        if targetItemSnapshot.hasProperty(.surface) {
            // Use safe snapshot accessor
            let snapshotsOnSurface = await engine.itemSnapshots(withParent: .item(targetItemID))

            if !snapshotsOnSurface.isEmpty {
                await engine.ioHandler.print("On the \(targetItemSnapshot.name) is:")
                for itemSnapshot in snapshotsOnSurface {
                    // TODO: Improve formatting
                    await engine.ioHandler.print("  A \(itemSnapshot.name)")
                }
            }
            // No message needed if surface is empty
        }

        // TODO: Add logic for examining doors, NPCs, etc.
        // TODO: Potentially mark item as touched (gameState.items[targetItemID]?.addProperty(.touched))?
    }
}
