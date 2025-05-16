import Foundation

/// Handles the "TAKE" context.command and its synonyms (e.g., "GET").
public struct TakeActionHandler: ActionHandler {
    public func validate(context: ActionContext) async throws {
        // 1. Ensure we have a direct object and it's an item
        guard let directObjectRef = context.command.directObject else {
            throw ActionResponse.prerequisiteNotMet("Take what?")
        }
        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet("You can only take items.")
        }

        // 2. Check if item exists
        let targetItem = try await context.engine.item(targetItemID)

        // 3. Check if player already has the item
        if targetItem.parent == .player {
            // Can't throw error here, need to report specific message.
            // Let process handle returning a specific ActionResult for this.
            // This validation passes if already held, process generates the message.
            return
        }

        // 4. Check if item is inside something invalid (non-container/non-surface)
        if case .item(let parentID) = targetItem.parent {
            let parentItem = try await context.engine.item(parentID)

            // Fail only if the parent is NOT a container and NOT a surface.
            // We allow taking from *closed* containers here; reachability handles closed state later.
            let isContainer = parentItem.hasFlag(.isContainer)
            let isSurface = parentItem.hasFlag(.isSurface)
            if !isContainer && !isSurface {
                // Custom message similar to Zork's, using the plain name.
                throw ActionResponse.prerequisiteNotMet("You can't take things out of the \(parentItem.name).")
            }
        }

        // 5. Handle specific container closed errors before general unreachability
        if case .item(let parentID) = targetItem.parent {
            let container = try await context.engine.item(parentID)
            if container.hasFlag(.isContainer) && !container.hasFlag(.isOpen) {
                if targetItem.hasFlag(.isTouched) || container.hasFlag(.isTransparent) {
                    throw ActionResponse.containerIsClosed(parentID)
                } else {
                    throw ActionResponse.itemNotAccessible(targetItemID)
                }
            }
        }

        // 6. Check reachability using ScopeResolver (general check)
        guard await context.engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }

        // 7. Check if the item is takable
        guard targetItem.hasFlag(.isTakable) else {
            throw ActionResponse.itemNotTakable(targetItemID)
        }

        // 8. Check capacity <-- Check added here
        guard await context.engine.playerCanCarry(targetItem) else {
            throw ActionResponse.playerCannotCarryMore
        }
    }

    public func process(context: ActionContext) async throws -> ActionResult {
        guard let directObjectRef = context.command.directObject,
              case .item(let targetItemID) = directObjectRef else {
            // This should ideally be caught by validate.
            throw ActionResponse.internalEngineError("Take: directObject was not an item in process.")
        }
        let targetItem = try await context.engine.item(targetItemID)

        // Handle "already have" case detected (but not thrown) in validate
        if targetItem.parent == .player {
            return ActionResult("You already have that.")
        }

        // --- Calculate State Changes ---
        var stateChanges: [StateChange] = []

        // Change 1: Parent
        let update = await context.engine.move(targetItem, to: .player)
        stateChanges.append(update)

        // Change 2: Set `.isTouched` flag if not already set
        if let update = await context.engine.setFlag(.isTouched, on: targetItem) {
            stateChanges.append(update)
        }

        // Change 3: Pronoun ("it")
        if let update = await context.engine.updatePronouns(to: targetItem) {
            stateChanges.append(update)
        }

        // --- Prepare Result ---
        return ActionResult(
            message: "Taken.",
            stateChanges: stateChanges
        )
    }

    // Rely on default postProcess.
}
