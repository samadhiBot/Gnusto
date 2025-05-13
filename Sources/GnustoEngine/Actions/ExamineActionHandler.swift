import Foundation

/// Handles the "EXAMINE" context.command and its synonyms (e.g., "LOOK AT", "DESCRIBE").
public struct ExamineActionHandler: ActionHandler {
    public func validate(context: ActionContext) async throws {
        // 1. Ensure we have a direct object
        guard let targetItemID = context.command.directObject else {
            throw ActionResponse.custom("Examine what?")
        }

        // 2. Check if item exists
        guard let _ = try? await context.engine.item(targetItemID) else {
            throw ActionResponse.unknownItem(targetItemID)
        }

        // 3. Check reachability
        guard
            await context.engine.scopeResolver
                .itemsReachableByPlayer()
                .contains(targetItemID)
        else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }
    }

    public func process(context: ActionContext) async throws -> ActionResult {
        let targetItem = try await context.engine.item(context.command.directObject)

        var stateChanges: [StateChange] = []

        // Special case: examining 'self' should not record any state changes
        if targetItem.id != "self" {
            // --- State Change: Mark as Touched ---
            if let update = await context.engine.flag(targetItem, with: .isTouched) {
                stateChanges.append(update)
            }

            // --- State Change: Update pronouns ---
            if let update = await context.engine.updatePronouns(to: targetItem) {
                stateChanges.append(update)
            }
        }

        // --- Determine Message ---
        let message: String

        // Priority 1: Readable Text (Check dynamic value)
        if targetItem.hasFlag(.isReadable),
           let readText: String = try? await context.engine.fetch(targetItem.id, .readText),
           !readText.isEmpty
        {
            message = readText
        }
        // Priority 2: Container/Door Description
        else if targetItem.hasFlag(.isContainer) || targetItem.hasFlag(.isDoor) {
            message = try await describeContainerOrDoor(
                targetItem: targetItem,
                engine: context.engine
            )
        }
        // Priority 3: Surface Description
        else if targetItem.hasFlag(.isSurface) {
            message = await describeSurface(
                targetItem: targetItem,
                engine: context.engine
            )
        }
        // Priority 4: Dynamic Long Description
        else {
            // Use the registry to generate the description using the item ID and key
            message = await context.engine.generateDescription(
                for: targetItem.id,
                key: .description,
                engine: context.engine
            )
        }

        // --- Create Result ---
        return ActionResult(
            message: message,
            stateChanges: stateChanges
        )
    }

    // MARK: - Private Helpers (Adapted to return String)

    /// Helper function to generate description for containers or doors.
    private func describeContainerOrDoor(
        targetItem: Item,
        engine: GameEngine
    ) async throws -> String {
        var descriptionParts: [String] = []

        // Start with the item's main description, using the registry with ID and key
        let baseDescription = await engine.generateDescription(
            for: targetItem.id,
            key: .description,
            engine: engine
        )
        descriptionParts.append(baseDescription)

        // Check dynamic property for open state
        let isOpen: Bool = try await engine.fetch(targetItem.id, .isOpen)
        let isTransparent = targetItem.hasFlag(.isTransparent)

        if isOpen || isTransparent {
            let contents = await engine.items(in: .item(targetItem.id))
            if contents.isEmpty {
                descriptionParts.append("The \(targetItem.name) is empty.")
            } else {
                let itemNames = contents.listWithIndefiniteArticles
                descriptionParts.append("The \(targetItem.name) contains \(itemNames).")
            }
        } else {
            descriptionParts.append("The \(targetItem.name) is closed.")
        }
        return descriptionParts.joined(separator: " ")
    }

    /// Helper function to generate description for surfaces.
    private func describeSurface(targetItem: Item, engine: GameEngine) async -> String {
        var descriptionParts: [String] = []

        // Start with the item's main description, using the registry with ID and key
        let baseDescription = await engine.generateDescription(
            for: targetItem.id,
            key: .description,
            engine: engine
        )
        descriptionParts.append(baseDescription)

        // List items on the surface
        let contents = await engine.items(in: .item(targetItem.id))
        if !contents.isEmpty {
            let itemNames = contents.listWithIndefiniteArticles
            descriptionParts.append(
                "On the \(targetItem.name) is \(itemNames)."
            )
        }

        return descriptionParts.joined(separator: " ")
    }
}
