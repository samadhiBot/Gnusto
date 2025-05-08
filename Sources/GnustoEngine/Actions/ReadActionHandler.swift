import Foundation

/// Handles the "READ" context.command.
public struct ReadActionHandler: ActionHandler {
    public func validate(context: ActionContext) async throws {
        // 1. Ensure we have a direct object
        guard let targetItemID = context.command.directObject else {
            throw ActionError.customResponse("Read what?")
        }

        // 2. Check if item exists
        guard let targetItem = await context.engine.item(targetItemID) else {
            throw ActionError.unknownItem(targetItemID)
        }

        // 3. Check if room is lit (unless item provides light)
        let currentLocationID = await context.engine.gameState.player.currentLocationID
        let isLit = await context.engine.scopeResolver.isLocationLit(locationID: currentLocationID)
        guard isLit else {
            throw ActionError.roomIsDark
        }

        // 4. Check reachability
        let reachableItems = await context.engine.scopeResolver.itemsReachableByPlayer()
        guard reachableItems.contains(targetItemID) else {
            throw ActionError.itemNotAccessible(targetItemID)
        }

        // 5. Check if item is readable
        guard targetItem.hasFlag(.isReadable) else {
            throw ActionError.itemNotReadable(targetItemID)
        }
    }

    public func process(context: ActionContext) async throws -> ActionResult {
        guard let targetItemID = context.command.directObject else {
            throw ActionError.internalEngineError(
                "READ context.command reached process without direct object."
            )
        }
        guard let targetItem = await context.engine.item(targetItemID) else {
            throw ActionError.internalEngineError(
                "Target item '\(targetItemID)' disappeared between validate and process."
            )
        }

        // --- State Change: Mark as Touched ---
        var stateChanges: [StateChange] = []

        if let touchedStateChange = await context.engine.flag(targetItem, with: .isTouched) {
            stateChanges.append(touchedStateChange)
        }

        // --- State Change: Update pronoun "it" ---
        if let pronounStateChange = await context.engine.pronounStateChange(for: targetItem) {
            stateChanges.append(pronounStateChange)
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
