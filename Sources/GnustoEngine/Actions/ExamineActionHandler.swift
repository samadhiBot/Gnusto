import Foundation

/// Handles the "EXAMINE" context.command and its synonyms (e.g., "LOOK AT", "DESCRIBE").
public struct ExamineActionHandler: EnhancedActionHandler {

    public init() {}

    // MARK: - EnhancedActionHandler Methods

    public func validate(context: ActionContext) async throws {
        // 1. Ensure we have a direct object
        guard let targetItemID = context.command.directObject else {
            throw ActionError.customResponse("Examine what?")
        }

        // 2. Check if item exists
        guard await context.engine.item(with: targetItemID) != nil else {
            throw ActionError.internalEngineError("Parser resolved non-existent item ID '\(targetItemID)'.")
        }

        // 3. Check reachability
        let isReachable = await context.engine.scopeResolver.itemsReachableByPlayer().contains(targetItemID)
        guard isReachable else {
            throw ActionError.itemNotAccessible(targetItemID)
        }
    }

    public func process(context: ActionContext) async throws -> ActionResult {
        guard let targetItemID = context.command.directObject else {
            throw ActionError.internalEngineError("Examine context.command reached process without direct object.")
        }
        guard let targetItem = await context.engine.item(with: targetItemID) else {
            throw ActionError.internalEngineError("Target item '\(targetItemID)' disappeared between validate and process.")
        }

        // --- State Change: Mark as Touched ---
        var stateChanges: [StateChange] = []
        let initialProperties = targetItem.properties // Use initial state
        if !initialProperties.contains(.touched) {
            stateChanges.append(StateChange(
                entityId: .item(targetItemID),
                propertyKey: .itemProperties,
                oldValue: .itemPropertySet(initialProperties),
                newValue: .itemPropertySet(initialProperties.union([.touched]))
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
            message = await describeContainerOrDoor(targetItem: targetItem, engine: context.engine)
        }
        // Priority 3: Surface Description
        else if targetItem.hasProperty(.surface) {
            message = await describeSurface(targetItem: targetItem, engine: context.engine)
        }
        // Priority 4: Dynamic Long Description
        else {
            // Use the new engine describe method which handles nil handlers internally
            message = await context.engine.describe(item: targetItem)
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
    private func describeContainerOrDoor(targetItem: Item, engine: GameEngine) async -> String {
        var descriptionParts: [String] = []

        // Start with the item's main description, using the new engine method
        let baseDescription = await engine.describe(item: targetItem)
        descriptionParts.append(baseDescription)

        let isOpen = targetItem.hasProperty(.open)
        let isTransparent = targetItem.hasProperty(.transparent)

        if isOpen || isTransparent {
            let contents = await engine.items(withParent: .item(targetItem.id))
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

        // Start with the item's main description, using the new engine method
        let baseDescription = await engine.describe(item: targetItem)
        descriptionParts.append(baseDescription)

        // List items on the surface
        let contents = await engine.items(withParent: .item(targetItem.id))
        if !contents.isEmpty {
            let itemNames = contents.listWithIndefiniteArticles
            descriptionParts.append(
                "On the \(targetItem.name) is \(itemNames)."
            )
        }

        return descriptionParts.joined(separator: " ")
    }
}
