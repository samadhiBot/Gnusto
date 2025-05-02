import Foundation

/// Handles the "CLOSE" context.command.
public struct CloseActionHandler: EnhancedActionHandler {

    public init() {}

    // MARK: - EnhancedActionHandler

    public func validate(context: ActionContext) async throws {
        // 1. Ensure we have a direct object
        guard let targetItemID = context.command.directObject else {
            throw ActionError.prerequisiteNotMet("Close what?")
        }

        // 2. Check if item exists
        guard let targetItem = await context.engine.item(with: targetItemID) else {
            // Standard approach: If parser resolved it, but it's gone, treat as inaccessible.
            throw ActionError.itemNotAccessible(targetItemID)
        }

        // 3. Check reachability using ScopeResolver
        let reachableItems = await context.engine.scopeResolver.itemsReachableByPlayer()
        guard reachableItems.contains(targetItemID) else {
            throw ActionError.itemNotAccessible(targetItemID)
        }

        // 4. Check if item is closeable (using .openable for symmetry)
        guard targetItem.hasProperty(.openable) else {
            throw ActionError.itemNotCloseable(targetItemID)
        }

        // 5. Check if already closed
        guard targetItem.hasProperty(.open) else {
            // Don't throw, let process handle the specific message
            return
        }

        // Note: Closing doesn't usually depend on locked status.
    }

    public func process(context: ActionContext) async throws -> ActionResult {
        guard let targetItemID = context.command.directObject else {
            // Should be caught by validate, but defensive check.
            throw ActionError.internalEngineError("Close context.command reached process without direct object.")
        }
        guard let targetItem = await context.engine.item(with: targetItemID) else {
            // Should be caught by validate.
            throw ActionError.internalEngineError("Close context.command target item disappeared between validate and process.")
        }

        // Handle "already closed" case detected (but not thrown) in validate
        if !targetItem.hasProperty(.open) {
            return ActionResult(success: false, message: "The \(targetItem.name) is already closed.")
        }

        // --- Calculate State Changes ---
        var stateChanges: [StateChange] = []

        // Change 1: Properties (remove .open, add .touched)
        let oldProperties = targetItem.properties
        var newProperties = oldProperties
        newProperties.remove(.open) // Remove the open flag
        newProperties.insert(.touched) // Mark as touched

        if oldProperties != newProperties {
            let propertiesChange = StateChange(
                entityId: .item(targetItemID),
                propertyKey: .itemProperties,
                oldValue: .itemPropertySet(oldProperties),
                newValue: .itemPropertySet(newProperties)
            )
            stateChanges.append(propertiesChange)
        }

        // Closing doesn't usually affect pronouns like taking does.

        // --- Prepare Result ---
        return ActionResult(
            success: true,
            message: "You close the \(targetItem.name).", // Use plain name
            stateChanges: stateChanges,
            sideEffects: []
        )
    }

    // Rely on default postProcess to print the message.
}

// TODO: Add/verify ActionError cases: .itemNotCloseable, .itemAlreadyClosed
