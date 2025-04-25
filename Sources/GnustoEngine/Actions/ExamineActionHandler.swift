import Foundation

/// Handles the "EXAMINE" command and its synonyms (e.g., "LOOK AT", "DESCRIBE").
public struct ExamineActionHandler: ActionHandler {

    public init() {}

    public func perform(command: Command, engine: GameEngine) async throws {
        // 1. Ensure we have a direct object
        guard let targetItemID = command.directObject else {
            await engine.output("Examine what?") // TODO: Zork message?
            return
        }

        // 2. Check if item exists and is accessible
        guard let targetItem = await engine.itemSnapshot(with: targetItemID) else {
            throw ActionError.internalEngineError("Parser resolved non-existent item ID '\(targetItemID)'.")
        }

        let isReachable = await engine.scopeResolver.itemsReachableByPlayer().contains(targetItemID)
        guard isReachable else {
            // Error message like "You can't see any... here" is handled by engine's report(actionError:)
            throw ActionError.itemNotAccessible(targetItemID)
        }

        // Mark as touched regardless of what happens next (standard Zork behavior)
        await engine.updateItemProperties(itemID: targetItemID, adding: .touched)

        // 4. Check if item is readable (Zork V-EXAMINE prioritizes P?TEXT)
        if targetItem.hasProperty(.readable), let text = targetItem.readableText, !text.isEmpty {
            await engine.output(text) // Print the readable text
            return
        }

        // 5. Check if item is a container or door (Zork V-EXAMINE calls V-LOOK-INSIDE)
        if targetItem.hasProperty(.container) || targetItem.hasProperty(.door) {
            await examineContainerOrDoor(targetItem: targetItem, engine: engine)
            return
        }

        // 6. Get the item's description using the description handler
        if let descriptionHandler = targetItem.description {
            let description = await engine.descriptionHandlerRegistry.generateDescription(
                for: targetItem,
                using: descriptionHandler,
                engine: engine
            )
            await engine.output(description)
        } else {
            // Default message if no description handler
            await engine.output("There's nothing special about the \(targetItem.name).")
        }
    }

    /// Helper function to handle examining containers or doors.
    private func examineContainerOrDoor(targetItem: ItemSnapshot, engine: GameEngine) async {
        // Print the item's main description first, if available
        if let descriptionHandler = targetItem.description {
            let description = await engine.descriptionHandlerRegistry.generateDescription(
                for: targetItem,
                using: descriptionHandler,
                engine: engine
            )
            await engine.output(description)
        } else {
            // Fallback if no specific description
            await engine.output("You examine the \(targetItem.name).")
        }

        let isOpen = targetItem.hasProperty(.open)
        let isTransparent = targetItem.hasProperty(.transparent)

        if isOpen || isTransparent {
            let contents = await engine.itemSnapshots(withParent: .item(targetItem.id))
            if contents.isEmpty {
                await engine.output("The \(targetItem.name) is empty.")
            } else {
                await engine.output("The \(targetItem.name) contains:")
                for item in contents {
                    // TODO: Proper sentence construction with articles
                    await engine.output("  A \(item.name)")
                }
            }
        } else {
            // Closed and not transparent
            await engine.output("The \(targetItem.name) is closed.")
        }
    }
}
