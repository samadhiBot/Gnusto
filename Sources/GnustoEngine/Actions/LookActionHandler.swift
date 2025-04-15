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

        // --- Custom Hook: On Examine Item ---
        // Check if a custom handler wants to override the default behavior
        if let handler = engine.onExamineItem {
            if await handler(engine, targetItemID) {
                return // Custom handler took care of it, so we are done.
            }
        }
        // ----------------------------------

        // Use safe snapshot accessor
        guard let targetItemSnapshot = await engine.itemSnapshot(with: targetItemID) else {
            // Should not happen if parser resolved correctly
            throw ActionError.internalEngineError("Resolved item ID \(targetItemID) not found in game state.")
        }

        // Print the item's description, or a default message
        let description = targetItemSnapshot.description ?? "You see nothing special about the \(targetItemSnapshot.name)."
        await engine.ioHandler.print(description)

        // If the item is a container, list its *visible* contents
        if targetItemSnapshot.hasProperty(.container) {
            // Check if contents are visible (open or transparent)
            let isOpen = targetItemSnapshot.hasProperty(.open)
            let isTransparent = targetItemSnapshot.hasProperty(.transparent) // Assumes .transparent property exists

            if isOpen || isTransparent {
                // Use safe snapshot accessor
                let contentsSnapshots = await engine.itemSnapshots(withParent: .item(targetItemID))

                if contentsSnapshots.isEmpty {
                    await engine.ioHandler.print("The \(targetItemSnapshot.name) is empty.")
                } else {
                    await engine.ioHandler.print("The \(targetItemSnapshot.name) contains:")
                    for itemSnapshot in contentsSnapshots {
                        // TODO: Improve formatting (e.g., proper sentence, articles)
                        await engine.ioHandler.print("  A \(itemSnapshot.name)")
                    }
                }
            } else {
                // Container is closed and not transparent
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
