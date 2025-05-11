import Foundation

/// Handles the "READ" context.command.
public struct ReadActionHandler: ActionHandler {
    public func validate(context: ActionContext) async throws {
        // 1. Ensure we have a direct object
        guard let targetItemID = context.command.directObject else {
            throw ActionResponse.custom("Read what?")
        }

        // 2. Check if item exists
        guard let targetItem = await context.engine.item(targetItemID) else {
            throw ActionResponse.unknownItem(targetItemID)
        }

        // 3. Check if room is lit (unless item provides light)
        let currentLocationID = await context.engine.gameState.player.currentLocationID
        let isLit = await context.engine.scopeResolver.isLocationLit(locationID: currentLocationID)
        guard isLit else {
            throw ActionResponse.roomIsDark
        }

        // 4. Check reachability
        let reachableItems = await context.engine.scopeResolver.itemsReachableByPlayer()
        guard reachableItems.contains(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }

        // 5. Check if item is readable
        guard targetItem.hasFlag(.isReadable) else {
            throw ActionResponse.itemNotReadable(targetItemID)
        }
    }

    public func process(context: ActionContext) async throws -> ActionResult {
        guard let targetItemID = context.command.directObject else {
            throw ActionResponse.internalEngineError(
                "READ context.command reached process without direct object."
            )
        }
        guard let targetItem = await context.engine.item(targetItemID) else {
            throw ActionResponse.internalEngineError(
                "Target item '\(targetItemID)' disappeared between validate and process."
            )
        }

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
            let textToRead: String = try await context.engine.fetch(targetItemID, .readText)
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
            success: true,
            message: message,
            stateChanges: stateChanges
        )
    }
}
