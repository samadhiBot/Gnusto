import Foundation

/// Handles the "TOUCH" context.command and its synonyms (e.g., "FEEL", "RUB", "PAT").
public struct TouchActionHandler: ActionHandler {
    public func validate(context: ActionContext) async throws {
        // 1. Ensure we have a direct object and it's an item
        guard let directObjectRef = context.command.directObject else {
            throw ActionResponse.custom("Touch what?")
        }
        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet("You can only touch items.")
        }

        // 2. Check if item exists (engine.item() will throw if not found)
        let _ = try await context.engine.item(targetItemID)

        // 3. Check reachability
        guard await context.engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }
    }

    public func process(context: ActionContext) async throws -> ActionResult {
        guard let directObjectRef = context.command.directObject,
              case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.internalEngineError("Touch: directObject was not an item in process.")
        }
        let targetItem = try await context.engine.item(targetItemID)

        // --- State Change: Mark as Touched ---
        var stateChanges: [StateChange] = []

        if let addTouchedFlag = await context.engine.flag(targetItem, with: .isTouched) {
            stateChanges.append(addTouchedFlag)
        }

        // TODO: Allow item-specific touch actions via ItemActionHandler?

        // --- Create Result ---
        return ActionResult(
            message: "You feel nothing special.",
            stateChanges: stateChanges
        )
    }
}
