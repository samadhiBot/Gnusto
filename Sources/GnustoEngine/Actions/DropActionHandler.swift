import Foundation

/// Handles the "DROP" command and its synonyms (e.g., "PUT DOWN").
public struct DropActionHandler: EnhancedActionHandler {

    public init() {}

    // MARK: - EnhancedActionHandler

    public func validate(
        command: Command,
        engine: GameEngine
    ) async throws {
        // 1. Ensure we have a direct object
        guard let targetItemID = command.directObject else {
            throw ActionError.prerequisiteNotMet("Drop what?")
        }

        // 2. Check if item exists
        guard let targetItem = await engine.item(with: targetItemID) else {
            // If parser resolved it, but it's gone, treat as inaccessible/not held.
            // For DROP, the more specific error is relevant.
            throw ActionError.itemNotHeld(targetItemID) // Or should this be itemNotAccessible?
        }

        // 3. Check if player is holding the item
        guard targetItem.parent == .player else {
            // Don't throw, let process handle the specific message
            return
        }

        // 4. Check if item is droppable (not fixed)
        if targetItem.hasProperty(.fixed) {
            throw ActionError.itemNotDroppable(targetItemID)
        }
    }

    public func process(
        command: Command,
        engine: GameEngine
    ) async throws -> ActionResult {
        guard let targetItemID = command.directObject else {
            throw ActionError.internalEngineError("Drop command reached process without direct object.")
        }
        guard let targetItem = await engine.item(with: targetItemID) else {
            // Should be caught by validate.
            throw ActionError.internalEngineError("Drop command target item disappeared between validate and process.")
        }

        // Handle "not holding" case detected (but not thrown) in validate
        if targetItem.parent != .player {
            return ActionResult(success: false, message: "You aren't holding the \(targetItem.name).")
        }

        // --- Calculate State Changes ---
        let currentLocationID = await engine.gameState.player.currentLocationID
        var stateChanges: [StateChange] = []

        // Change 1: Parent
        let parentChange = StateChange(
            entityId: .item(targetItemID),
            propertyKey: .itemParent,
            oldValue: .parentEntity(.player),
            newValue: .parentEntity(.location(currentLocationID))
        )
        stateChanges.append(parentChange)

        // Change 2: Properties (add .touched, remove .worn)
        let oldProperties = targetItem.properties
        var newProperties = oldProperties
        newProperties.insert(.touched) // Ensure it's marked touched
        newProperties.remove(.worn)   // No longer worn if dropped

        if oldProperties != newProperties {
            let propertiesChange = StateChange(
                entityId: .item(targetItemID),
                propertyKey: .itemProperties,
                oldValue: .itemProperties(oldProperties),
                newValue: .itemProperties(newProperties)
            )
            stateChanges.append(propertiesChange)
        }

        // Dropping usually doesn't affect pronouns unless maybe it was the last thing referred to?
        // For simplicity, let's not change pronouns on drop for now.
        // We could potentially clear the pronoun if it referred *only* to the dropped item.

        // --- Prepare Result ---
        return ActionResult(
            success: true,
            message: "Dropped.", // Zork 1 message
            stateChanges: stateChanges,
            sideEffects: []
        )
    }

    // Rely on default postProcess to print the message.
}
