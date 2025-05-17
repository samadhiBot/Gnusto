import Foundation

/// Handles the "OPEN" context.command.
public struct OpenActionHandler: ActionHandler {
    public func validate(context: ActionContext) async throws {
        // 1. Ensure we have a direct object and it's an item
        guard let directObjectRef = context.command.directObject else {
            throw ActionResponse.prerequisiteNotMet("Open what?")
        }
        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet("You can only open items.")
        }

        // 2. Check if item exists and is accessible using ScopeResolver
        let targetItem = try await context.engine.item(targetItemID)

        // Use ScopeResolver to determine reachability
        guard await context.engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }

        // 3. Check if item is openable
        guard targetItem.hasFlag(.isOpenable) else {
            throw ActionResponse.itemNotOpenable(targetItemID)
        }

        // 4. Check if locked
        if targetItem.hasFlag(.isLocked) {
            throw ActionResponse.itemIsLocked(targetItemID)
        }
    }

    public func process(context: ActionContext) async throws -> ActionResult {
        guard let directObjectRef = context.command.directObject,
              case .item(let targetItemID) = directObjectRef else {
            // Should not be reached if validate is correct.
            throw ActionResponse.internalEngineError("Open: directObject was not an item in process.")
        }

        let targetItem = try await context.engine.item(targetItemID)

        // Check if already open
        if try await context.engine.fetch(targetItem.id, .isOpen) {
            throw ActionResponse.itemAlreadyOpen(targetItemID)
        }

        var stateChanges: [StateChange] = []

        if let update = await context.engine.setFlag(.isOpen, on: targetItem) {
            stateChanges.append(update)
        }

        if let update = await context.engine.setFlag(.isTouched, on: targetItem) {
            stateChanges.append(update)
        }

        // Update pronoun
        if let update = await context.engine.updatePronouns(to: targetItem) {
            stateChanges.append(update)
        }

        // Prepare the result
        return ActionResult(
            message: "You open the \(targetItem.name).",
            stateChanges: stateChanges
        )
    }

    // Rely on default postProcess to print the message.
    // Engine's execute method handles applying the stateChanges.
}

// TODO: Add/verify ActionResponse cases: .itemNotOpenable, .itemAlreadyOpen, .itemIsLocked
