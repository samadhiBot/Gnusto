import Foundation

/// Handles the "READ" context.command.
public struct ReadActionHandler: ActionHandler {
    public func validate(context: ActionContext) async throws {
        // 1. Ensure we have a direct object and it's an item
        guard let directObjectRef = context.command.directObject else {
            throw ActionResponse.custom("Read what?")
        }
        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet("You can only read items.")
        }

        // 2. Check if item exists
        let targetItem = try await context.engine.item(targetItemID)

        // 3. Check if room is lit (unless item provides light)
        guard await context.engine.playerLocationIsLit() else {
            throw ActionResponse.roomIsDark
        }

        // 4. Check reachability
        guard await context.engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }

        // 5. Check if item is readable
        guard targetItem.hasFlag(.isReadable) else {
            throw ActionResponse.itemNotReadable(targetItemID)
        }
    }

    public func process(context: ActionContext) async throws -> ActionResult {
        guard let directObjectRef = context.command.directObject,
              case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.internalEngineError("Read: directObject was not an item in process.")
        }
        let targetItem = try await context.engine.item(targetItemID)

        // --- State Change: Mark as Touched ---
        var stateChanges: [StateChange] = []

        if let addTouchedFlag = await context.engine.flag(targetItem, with: .isTouched) {
            stateChanges.append(addTouchedFlag)
        }

        // --- State Change: Update pronoun "it" ---
        if let updatePronoun = await context.engine.updatePronouns(to: targetItem) {
            stateChanges.append(updatePronoun)
        }

        // --- Determine Message ---
        let message: String

        // Fetch text from dynamic values
        do {
            let textToRead: String = try await context.engine.fetch(targetItem.id, .readText)
            if textToRead.isEmpty {
                message = "There's nothing written on the \(targetItem.name)."
            } else {
                message = textToRead
            }
        } catch {
            message = "There's nothing written on the \(targetItem.name)."
        }

        // --- Create Result ---
        return ActionResult(
            message: message,
            stateChanges: stateChanges
        )
    }
}
