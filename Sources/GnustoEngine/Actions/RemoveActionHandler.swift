import Foundation

/// Handles the "REMOVE" command and its synonyms (e.g., "DOFF", "TAKE OFF").
public struct RemoveActionHandler: EnhancedActionHandler {

    public init() {}

    // MARK: - EnhancedActionHandler

    public func validate(
        command: Command,
        engine: GameEngine
    ) async throws {
        // 1. Ensure we have a direct object
        guard let targetItemID = command.directObject else {
            throw ActionError.prerequisiteNotMet("Remove what?")
        }

        // 2. Check if the item exists and is held by the player
        guard let targetItem = await engine.item(with: targetItemID),
              targetItem.parent == .player else
        {
            throw ActionError.itemNotHeld(targetItemID)
        }

        // 3. Check if the (held) item is currently worn
        guard targetItem.hasProperty(.worn) else {
            throw ActionError.itemIsNotWorn(targetItemID)
        }

        // 4. Check if the item is fixed (e.g., cursed amulet)
        guard !targetItem.hasProperty(.fixed) else {
            throw ActionError.itemNotRemovable(targetItemID)
        }
    }

    public func process(
        command: Command,
        engine: GameEngine
    ) async throws -> ActionResult {
        // IDs and validation guaranteed by validate()
        let targetItemID = command.directObject!
        guard let itemSnapshot = await engine.item(with: targetItemID) else {
            // Should not happen if validate passed
            throw ActionError.internalEngineError("Item snapshot disappeared between validate and process for REMOVE.")
        }

        var stateChanges: [StateChange] = []

        // Calculate property changes: Remove .worn, add .touched
        let oldProps = itemSnapshot.properties
        var newProps = oldProps
        newProps.remove(.worn)
        newProps.insert(.touched) // Taking off implies touching

        if oldProps != newProps {
            stateChanges.append(StateChange(
                entityId: .item(targetItemID),
                propertyKey: .itemProperties,
                oldValue: .itemPropertySet(oldProps),
                newValue: .itemPropertySet(newProps)
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
        let message = "You take off the \(itemSnapshot.name)."
        return ActionResult(
            success: true,
            message: message,
            stateChanges: stateChanges
        )
    }

    // Remove the old perform method
    /*
    public func perform(command: Command, engine: GameEngine) async throws {
        // ... old implementation ...
    }
    */
}
