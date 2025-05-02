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
        guard let targetItem = await engine.item(with: targetItemID) else {
            // Use standard not accessible error for non-existent items
            throw ActionError.itemNotAccessible(targetItemID)
        }

        // 3. Check if player already has the item
        if targetItem.parent == .player {
            // Can't throw error here, need to report specific message.
            // Let process handle returning a specific ActionResult for this.
            // This validation passes if already held, process generates the message.
            return
        }

        // 4. Check if item is inside something invalid (non-container/non-surface)
        if case .item(let parentID) = targetItem.parent,
           let parentItem = await engine.item(with: parentID) {
            // Fail only if the parent is NOT a container and NOT a surface.
            // We allow taking from *closed* containers here; reachability handles closed state later.
            let isContainer = parentItem.hasProperty(.container)
            let isSurface = parentItem.hasProperty(.surface)
            if !isContainer && !isSurface {
                // Custom message similar to Zork's, using the plain name.
                throw ActionError.prerequisiteNotMet("You can't take things out of the \(parentItem.name).")
            }
        }

        // 5. Check reachability using ScopeResolver (general check)
        let reachableItems = await engine.scopeResolver.itemsReachableByPlayer()
        guard reachableItems.contains(targetItemID) else {
            // Handle specific container closed errors before general unreachability
            if case .item(let parentID) = targetItem.parent,
               let container = await engine.item(with: parentID),
               container.hasProperty(.container),
               !container.hasProperty(.open) {
                throw ActionError.containerIsClosed(parentID)
            }
            // If not reachable for other reasons (e.g., too far, darkness affecting scope)
            throw ActionError.itemNotAccessible(targetItemID)
        }

        // 6. Check if the item is takable
        guard targetItem.hasProperty(.takable) else {
            throw ActionError.itemNotTakable(targetItemID)
        }

        // 7. Check capacity <-- Check added here
        guard await engine.playerCanCarry(targetItem) else {
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
        guard let targetItem = await engine.item(with: targetItemID) else {
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
            entityId: .item(targetItemID),
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
                entityId: .item(targetItemID),
                propertyKey: .itemProperties,
                oldValue: .itemPropertySet(oldProperties),
                newValue: .itemPropertySet(newProperties)
            )
            stateChanges.append(propertiesChange)
        }

        // Change 3: Pronoun ("it")
        let oldPronounValue = await engine.getPronounReference(pronoun: "it")
        let pronounChange = StateChange(
            entityId: .global,
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
