import Foundation

/// Handles the "EXAMINE" command and its synonyms (e.g., "LOOK AT", "DESCRIBE").
public struct ExamineActionHandler: EnhancedActionHandler {

    public init() {}

    // MARK: - EnhancedActionHandler Methods

    public func validate(command: Command, engine: GameEngine) async throws {
        // 1. Ensure we have a direct object
        guard let targetItemID = command.directObject else {
            throw ActionError.customResponse("Examine what?")
        }

        // 2. Check if item exists
        guard await engine.itemSnapshot(with: targetItemID) != nil else {
            throw ActionError.internalEngineError("Parser resolved non-existent item ID '\(targetItemID)'.")
        }

        // 3. Check reachability
        let isReachable = await engine.scopeResolver.itemsReachableByPlayer().contains(targetItemID)
        guard isReachable else {
            throw ActionError.itemNotAccessible(targetItemID)
        }
    }

    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        guard let targetItemID = command.directObject else {
            throw ActionError.internalEngineError("Examine command reached process without direct object.")
        }
        guard let targetItem = await engine.itemSnapshot(with: targetItemID) else {
            throw ActionError.internalEngineError("Target item '\(targetItemID)' disappeared between validate and process.")
        }

        // --- State Change: Mark as Touched ---
        var stateChanges: [StateChange] = []
        let initialProperties = targetItem.properties // Use initial state
        if !initialProperties.contains(.touched) {
            stateChanges.append(StateChange(
                entityId: .item(targetItemID),
                propertyKey: .itemProperties,
                oldValue: .itemProperties(initialProperties),
                newValue: .itemProperties(initialProperties.union([.touched]))
            ))
        }

        // --- Determine Message ---
        let message: String

        // Priority 1: Readable Text
        if targetItem.hasProperty(.readable), let text = targetItem.readableText, !text.isEmpty {
            message = text
        }
        // Priority 2: Container/Door Description
        else if targetItem.hasProperty(.container) || targetItem.hasProperty(.door) {
            message = await describeContainerOrDoor(targetItem: targetItem, engine: engine)
        }
        // Priority 3: Surface Description
        else if targetItem.hasProperty(.surface) {
            message = await describeSurface(targetItem: targetItem, engine: engine)
        }
        // Priority 4: Dynamic Long Description
        else if let descriptionHandler = targetItem.longDescription {
            message = await engine.descriptionHandlerRegistry.generateDescription(
                for: targetItem,
                using: descriptionHandler,
                engine: engine
            )
        }
        // Fallback: Default Message
        else {
            message = "There's nothing special about the \(targetItem.name)."
        }

        // --- Create Result ---
        return ActionResult(
            success: true,
            message: message,
            stateChanges: stateChanges
        )
    }

    // MARK: - Private Helpers (Adapted to return String)

    /// Helper function to generate description for containers or doors.
    private func describeContainerOrDoor(targetItem: ItemSnapshot, engine: GameEngine) async -> String {
        var descriptionParts: [String] = []

        // Start with the item's main description, if available
        if let descriptionHandler = targetItem.longDescription {
            let baseDescription = await engine.descriptionHandlerRegistry.generateDescription(
                for: targetItem,
                using: descriptionHandler,
                engine: engine
            )
            descriptionParts.append(baseDescription)
        } else {
            descriptionParts.append("You examine the \(targetItem.name).")
        }

        let isOpen = targetItem.hasProperty(.open)
        let isTransparent = targetItem.hasProperty(.transparent)

        if isOpen || isTransparent {
            let contents = await engine.itemSnapshots(withParent: .item(targetItem.id))
            if contents.isEmpty {
                descriptionParts.append("The \(targetItem.name) is empty.")
            } else {
                descriptionParts.append("The \(targetItem.name) contains:")
                for item in contents {
                    descriptionParts.append("  A \(item.name)")
                }
            }
        } else {
            descriptionParts.append("The \(targetItem.name) is closed.")
        }
        return descriptionParts.joined(separator: "\n")
    }

    /// Helper function to generate description for surfaces.
    private func describeSurface(targetItem: ItemSnapshot, engine: GameEngine) async -> String {
        var descriptionParts: [String] = []

        // Start with the item's main description, if available
        if let descriptionHandler = targetItem.longDescription {
            let baseDescription = await engine.descriptionHandlerRegistry.generateDescription(
                for: targetItem,
                using: descriptionHandler,
                engine: engine
            )
            descriptionParts.append(baseDescription)
        } else {
            descriptionParts.append("You examine the \(targetItem.name).")
        }

        // List items on the surface
        let contents = await engine.itemSnapshots(withParent: .item(targetItem.id))
        if !contents.isEmpty {
            let itemNames = contents.map(\.name).listWithIndefiniteArticles
            descriptionParts
                .append("On the \(targetItem.name) is \(itemNames).")
        }

        return descriptionParts.joined(separator: "\n")
    }
}
