import Foundation

/// Handles the "TAKE" command and its synonyms (e.g., "GET").
public struct TakeActionHandler: EnhancedActionHandler {
    public init() {}

    public func validate(
        command: Command,
        engine: GameEngine
    ) async throws {
        // 1. Ensure we have a direct object
        guard let targetItemID = command.directObject else {
            throw ActionError.prerequisiteNotMet("Take what?")
        }

        // 2. Check if item exists
        guard let targetItem = await engine.itemSnapshot(with: targetItemID) else {
            // Use standard not accessible error for non-existent items
            throw ActionError.itemNotAccessible(targetItemID)
        }

        // 3. Check if player already has the item
        if targetItem.parent == .player {
            // Can't throw error here, need to report specific message.
            // Let process handle returning a specific ActionResult for this.
            // Or add a specific ActionError? For now, let process handle it.
            // This validation passes if already held, process generates the message.
             return
        }

        // 4. Check reachability using ScopeResolver
        let reachableItems = await engine.scopeResolver.itemsReachableByPlayer()
        guard reachableItems.contains(targetItemID) else {
             // Handle specific container closed errors before general unreachability
             if case .item(let parentID) = targetItem.parent,
                let container = await engine.itemSnapshot(with: parentID),
                container.hasProperty(.container),
                !container.hasProperty(.open) {
                 throw ActionError.containerIsClosed(parentID)
             }
            throw ActionError.itemNotAccessible(targetItemID)
        }

        // 5. Check if the item is takable
        guard targetItem.hasProperty(.takable) else {
            throw ActionError.itemNotTakable(targetItemID)
        }

        // 6. Check capacity
        guard await engine.canPlayerCarry(itemSize: targetItem.size) else {
            throw ActionError.playerCannotCarryMore
        }
    }

    public func process(
        command: Command,
        engine: GameEngine
    ) async throws -> ActionResult {
        guard let targetItemID = command.directObject else {
            throw ActionError.internalEngineError("Take command reached process without direct object.")
        }
        guard let targetItem = await engine.itemSnapshot(with: targetItemID) else {
            // Should be caught by validate.
            throw ActionError.internalEngineError("Take command target item disappeared between validate and process.")
        }

        // Handle "already have" case detected (but not thrown) in validate
        if targetItem.parent == .player {
            return ActionResult(success: false, message: "You already have that.")
        }

        // --- Calculate State Changes ---
        var stateChanges: [StateChange] = []

        // Change 1: Parent
        let parentChange = StateChange(
            objectId: targetItemID,
            propertyKey: .itemParent,
            oldValue: .parentEntity(targetItem.parent),
            newValue: .parentEntity(.player)
        )
        stateChanges.append(parentChange)

        // Change 2: Properties (add .touched)
        let oldProperties = targetItem.properties
        var newProperties = oldProperties
        newProperties.insert(.touched)

        if oldProperties != newProperties {
            let propertiesChange = StateChange(
                objectId: targetItemID,
                propertyKey: .itemProperties,
                oldValue: .itemProperties(oldProperties),
                newValue: .itemProperties(newProperties)
            )
            stateChanges.append(propertiesChange)
        }

        // Change 3: Pronoun ("it")
        // TODO: Handle "them" for plural/multiple items? Requires parser changes.
        // Get current pronoun state using the engine helper
        let oldPronounValue = await engine.getPronounReference(pronoun: "it")
        let pronounChange = StateChange(
            objectId: "unused", // ObjectId is ignored for pronoun changes
            propertyKey: .pronounReference(pronoun: "it"),
            oldValue: oldPronounValue != nil ? .itemIDSet(oldPronounValue!) : nil,
            newValue: .itemIDSet([targetItemID])
        )
        stateChanges.append(pronounChange)

        // --- Prepare Result ---
        return ActionResult(
            success: true,
            message: "Taken.",
            stateChanges: stateChanges,
            sideEffects: []
        )
    }

    // Rely on default postProcess.
}
