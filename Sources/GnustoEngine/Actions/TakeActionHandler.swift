import Foundation

/// Handles the "TAKE" context.command and its synonyms (e.g., "GET").
public struct TakeActionHandler: EnhancedActionHandler {
    public init() {}

    public func validate(context: ActionContext) async throws {
        // 1. Ensure we have a direct object
        guard let targetItemID = context.command.directObject else {
            throw ActionError.prerequisiteNotMet("Take what?")
        }

        // 2. Check if item exists
        guard let targetItem = await context.engine.item(targetItemID) else {
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
           let parentItem = await context.engine.item(parentID) {
            // Fail only if the parent is NOT a container and NOT a surface.
            // We allow taking from *closed* containers here; reachability handles closed state later.
            let isContainer = parentItem.hasFlag(.isContainer)
            let isSurface = parentItem.hasFlag(.isSurface)
            if !isContainer && !isSurface {
                // Custom message similar to Zork's, using the plain name.
                throw ActionError.prerequisiteNotMet("You can't take things out of the \(parentItem.name).")
            }
        }

        // 5. Check reachability using ScopeResolver (general check)
        let reachableItems = await context.engine.scopeResolver.itemsReachableByPlayer()
        guard reachableItems.contains(targetItemID) else {
            // Handle specific container closed errors before general unreachability
            if case .item(let parentID) = targetItem.parent,
               let container = await context.engine.item(parentID),
               container.hasFlag(.isContainer),
               // Check dynamic property for open state
               await context.engine.getDynamicItemValue(itemID: parentID, key: .isOpen)?.toBool == false
            {
                throw ActionError.containerIsClosed(parentID)
            }
            // If not reachable for other reasons (e.g., too far, darkness affecting scope)
            throw ActionError.itemNotAccessible(targetItemID)
        }

        // 6. Check if the item is takable
        guard targetItem.hasFlag(.isTakable) else {
            throw ActionError.itemNotTakable(targetItemID)
        }

        // 7. Check capacity <-- Check added here
        guard await context.engine.playerCanCarry(targetItem) else {
            throw ActionError.playerCannotCarryMore
        }
    }

    public func process(context: ActionContext) async throws -> ActionResult {
        guard let targetItemID = context.command.directObject else {
            throw ActionError.internalEngineError("Take context.command reached process without direct object.")
        }
        guard let targetItem = await context.engine.item(targetItemID) else {
            // Should be caught by validate.
            throw ActionError.internalEngineError("Take context.command target item disappeared between validate and process.")
        }

        // Handle "already have" case detected (but not thrown) in validate
        if targetItem.parent == .player {
            return ActionResult(success: false, message: "You already have that.")
        }

        // --- Calculate State Changes ---
        var stateChanges: [StateChange] = []

        // Change 1: Parent
        let parentChange = StateChange(
            entityID: .item(targetItemID),
            attributeKey: .itemParent,
            oldValue: .parentEntity(targetItem.parent),
            newValue: .parentEntity(.player)
        )
        stateChanges.append(parentChange)

        // Change 2: Set `.isTouched` flag if not already set
        if targetItem.attributes[.isTouched] != true {
            let touchedChange = StateChange(
                entityID: .item(targetItemID),
                attributeKey: .itemAttribute(.isTouched),
                oldValue: targetItem.attributes[.isTouched] ?? false,
                newValue: true,
            )
            stateChanges.append(touchedChange)
        }

        // Change 3: Pronoun ("it")
        let oldPronounValue = await context.engine.getPronounReference(pronoun: "it")
        let pronounChange = StateChange(
            entityID: .global,
            attributeKey: .pronounReference(pronoun: "it"),
            oldValue: oldPronounValue.map { .itemIDSet($0) },
            newValue: .itemIDSet([targetItemID])
        )
        stateChanges.append(pronounChange)

        // --- Prepare Result ---
        return ActionResult(
            success: true,
            message: "Taken.",
            stateChanges: stateChanges
        )
    }

    // Rely on default postProcess.
}
