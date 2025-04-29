import Foundation

/// Handles the "TOUCH" command and its synonyms (e.g., "FEEL", "RUB", "PAT").
public struct TouchActionHandler: EnhancedActionHandler {

    public init() {}

    // MARK: - EnhancedActionHandler Methods

    public func validate(command: Command, engine: GameEngine) async throws {
        // 1. Ensure we have a direct object
        guard let targetItemID = command.directObject else {
            throw ActionError.customResponse("Touch what?")
        }

        // 2. Check if item exists
        guard let targetItem = await engine.itemSnapshot(with: targetItemID) else {
            throw ActionError.internalEngineError("Parser resolved item ID '\(targetItemID)' which does not exist.")
        }

        // 3. Check reachability
        // Inline check as ScopeResolver doesn't have this specific logic yet.
        let currentLocationID = await engine.playerLocationID()
        let itemParent = targetItem.parent
        var isReachable = false
        switch itemParent {
        case .location(let locID):
            isReachable = (locID == currentLocationID)
        case .item(let parentItemID):
            guard let parentItem = await engine.itemSnapshot(with: parentItemID) else {
                throw ActionError.internalEngineError("Item \(targetItemID) references non-existent parent item \(parentItemID).")
            }
            let parentParent = parentItem.parent
            let isParentItemInReach = (parentParent == .location(currentLocationID) || parentParent == .player)
            if isParentItemInReach {
                if parentItem.hasProperty(.surface) {
                    isReachable = true
                } else if parentItem.hasProperty(.container) {
                    guard parentItem.hasProperty(.open) else {
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

    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        guard let targetItemID = command.directObject else {
            throw ActionError.internalEngineError("TOUCH command reached process without direct object.")
        }

        // --- State Change: Mark as Touched ---
        var stateChanges: [StateChange] = []
        // Get snapshot again to ensure properties are current
        if let targetItem = await engine.itemSnapshot(with: targetItemID) {
            if !targetItem.hasProperty(.touched) {
                let change = StateChange(
                    entityId: .item(targetItemID),
                    propertyKey: .itemProperties,
                    oldValue: .itemProperties(targetItem.properties),
                    newValue: .itemProperties(targetItem.properties.union([.touched]))
                )
                stateChanges.append(change)
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
