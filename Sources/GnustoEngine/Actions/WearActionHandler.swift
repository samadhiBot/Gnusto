import Foundation

/// Handles the "WEAR" command and its synonyms (e.g., "DON").
public struct WearActionHandler: EnhancedActionHandler {

    public init() {}

    // MARK: - EnhancedActionHandler

    public func validate(
        command: Command,
        engine: GameEngine
    ) async throws {
        // 1. Ensure we have a direct object
        guard let targetItemID = command.directObject else {
            throw ActionError.prerequisiteNotMet("Wear what?")
        }

        // 2. Check if the item exists and is held by the player
        guard let targetItem = await engine.itemSnapshot(with: targetItemID),
              targetItem.parent == .player else
        {
            throw ActionError.itemNotHeld(targetItemID)
        }

        // 3. Check if the (held) item is wearable
        guard targetItem.hasProperty(.wearable) else {
            throw ActionError.itemNotWearable(targetItemID)
        }

        // 4. Check if already worn
        guard !targetItem.hasProperty(.worn) else {
            throw ActionError.itemIsAlreadyWorn(targetItemID)
        }
    }

    public func process(
        command: Command,
        engine: GameEngine
    ) async throws -> ActionResult {
        // IDs and validation guaranteed by validate()
        let targetItemID = command.directObject!
        guard let itemSnapshot = await engine.itemSnapshot(with: targetItemID) else {
            // Should not happen if validate passed
            throw ActionError.internalEngineError("Item snapshot disappeared between validate and process for WEAR.")
        }

        var stateChanges: [StateChange] = []

        // Calculate property changes: Add .worn and .touched
        let oldProps = itemSnapshot.properties
        var newProps = oldProps
        newProps.insert(.worn)
        newProps.insert(.touched) // Wearing implies touching

        if oldProps != newProps {
            stateChanges.append(StateChange(
                entityId: .item(targetItemID),
                propertyKey: .itemProperties,
                oldValue: .itemProperties(oldProps),
                newValue: .itemProperties(newProps)
            ))
        }

        // Update pronoun "it"
        stateChanges.append(StateChange(
            entityId: .global,
            propertyKey: .pronounReference(pronoun: "it"),
            oldValue: nil,
            newValue: .itemIDSet([targetItemID])
        ))

        // --- Prepare Result ---
        let message = "You put on the \(itemSnapshot.name)."
        return ActionResult(
            success: true,
            message: message,
            stateChanges: stateChanges
        )
    }
}
