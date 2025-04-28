import Foundation

/// Handles the "CLOSE" command.
public struct CloseActionHandler: EnhancedActionHandler {

    public init() {}

    // MARK: - EnhancedActionHandler

    public func validate(
        command: Command,
        engine: GameEngine
    ) async throws {
        // 1. Ensure we have a direct object
        guard let targetItemID = command.directObject else {
            throw ActionError.prerequisiteNotMet("Close what?")
        }

        // 2. Check if item exists
        guard let targetItem = await engine.itemSnapshot(with: targetItemID) else {
            // Standard approach: If parser resolved it, but it's gone, treat as inaccessible.
            throw ActionError.itemNotAccessible(targetItemID)
        }

        // 3. Check reachability using ScopeResolver
        let reachableItems = await engine.scopeResolver.itemsReachableByPlayer()
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

    public func process(
        command: Command,
        engine: GameEngine
    ) async throws -> ActionResult {
        guard let targetItemID = command.directObject else {
            // Should be caught by validate, but defensive check.
            throw ActionError.internalEngineError("Close command reached process without direct object.")
        }
        guard let targetItem = await engine.itemSnapshot(with: targetItemID) else {
            // Should be caught by validate.
            throw ActionError.internalEngineError("Close command target item disappeared between validate and process.")
        }

        // Handle "already closed" case detected (but not thrown) in validate
        if !targetItem.hasProperty(.open) {
            return ActionResult(success: false, message: "\(targetItem.theName.capitalizedFirst) is already closed.")
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
                oldValue: .itemProperties(oldProperties),
                newValue: .itemProperties(newProperties)
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
