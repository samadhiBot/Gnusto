import Foundation

/// Handles the "TOUCH" context.command and its synonyms (e.g., "FEEL", "RUB", "PAT").
public struct TouchActionHandler: EnhancedActionHandler {

    public init() {}

    // MARK: - EnhancedActionHandler Methods

    public func validate(context: ActionContext) async throws {
        // 1. Ensure we have a direct object
        guard let targetItemID = context.command.directObject else {
            throw ActionError.customResponse("Touch what?")
        }

        // 2. Check if item exists
        guard let targetItem = await context.engine.item(targetItemID) else {
            throw ActionError.unknownItem(targetItemID)        }

        // 3. Check reachability
        // Inline check as ScopeResolver doesn't have this specific logic yet.
        let currentLocationID = await context.engine.gameState.player.currentLocationID
        let itemParent = targetItem.parent
        var isReachable = false
        switch itemParent {
        case .location(let locID):
            isReachable = (locID == currentLocationID)
        case .item(let parentItemID):
            guard let parentItem = await context.engine.item(parentItemID) else {
                throw ActionError.unknownItem(parentItemID)
            }
            let parentParent = parentItem.parent
            let isParentItemInReach = (parentParent == .location(currentLocationID) || parentParent == .player)
            if isParentItemInReach {
                if parentItem.hasFlag(.isSurface) {
                    isReachable = true
                } else if parentItem.hasFlag(.isContainer) {
                    // Check dynamic property for open state
                    guard try await context.engine.fetch(parentItemID, .isOpen) else {
                        throw ActionError.prerequisiteNotMet("The \(parentItem.name) is closed.")
                    }
                    isReachable = true
                }
            }
        case .player:
            isReachable = true
        case .nowhere:
            isReachable = false
        }
        guard isReachable else {
            throw ActionError.itemNotAccessible(targetItemID)
        }
    }

    public func process(context: ActionContext) async throws -> ActionResult {
        guard let targetItemID = context.command.directObject else {
            throw ActionError.internalEngineError("TOUCH context.command reached process without direct object.")
        }

        // --- State Change: Mark as Touched ---
        var stateChanges: [StateChange] = []
        // Get snapshot again to ensure properties are current
        if let targetItem = await context.engine.item(targetItemID) {
            if targetItem.attributes[.isTouched] != true {
                stateChanges.append(StateChange(
                    entityID: .item(targetItemID),
                    attributeKey: .itemAttribute(.isTouched),
                    oldValue: targetItem.attributes[.isTouched] ?? false,
                    newValue: true,
                ))
            }
        } else {
            // Should not happen if validate passed
            throw ActionError.internalEngineError("Target item '\(targetItemID)' disappeared between validate and process for TOUCH.")
        }

        // TODO: Allow item-specific touch actions via ObjectActionHandler?

        // --- Create Result ---
        return ActionResult(
            success: true,
            message: "You feel nothing special.",
            stateChanges: stateChanges
        )
    }
}
