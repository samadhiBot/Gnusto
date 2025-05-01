import Foundation

/// Handles the "READ" command.
public struct ReadActionHandler: EnhancedActionHandler {

    public init() {}

    // MARK: - EnhancedActionHandler Methods

    public func validate(command: Command, engine: GameEngine) async throws {
        // 1. Ensure we have a direct object
        guard let targetItemID = command.directObject else {
            throw ActionError.customResponse("Read what?")
        }

        // 2. Check if item exists
        guard let targetItem = await engine.item(with: targetItemID) else {
            throw ActionError.internalEngineError("Parser resolved non-existent item ID '\(targetItemID)'.")
        }

        // 3. Check reachability
        let currentLocationID = await engine.gameState.player.currentLocationID
        let itemParent = targetItem.parent
        var isReachable = false
        switch itemParent {
        case .location(let locID):
            isReachable = (locID == currentLocationID)
        case .item(let parentItemID):
            guard let parentItem = await engine.item(with: parentItemID) else {
                throw ActionError.internalEngineError("Item \(targetItemID) references non-existent parent item \(parentItemID).")
            }
            let parentParent = parentItem.parent
            // Check if parent is in current location or held by player
            let isParentItemInReach = (parentParent == .location(currentLocationID) || parentParent == .player)
            if isParentItemInReach {
                // Check if parent allows access (surface or open container)
                if parentItem.hasProperty(.surface) || (parentItem.hasProperty(.container) && parentItem.hasProperty(.open)) {
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

        // 4. Check if room is lit (unless item provides light)
        let isLit = await engine.scopeResolver.isLocationLit(locationID: currentLocationID)
        let providesLight = targetItem.hasProperty(.lightSource) && targetItem.hasProperty(.on)
        guard isLit || providesLight else {
            throw ActionError.roomIsDark
        }

        // 5. Check if item is readable
        guard targetItem.hasProperty(.readable) else {
            throw ActionError.itemNotReadable(targetItemID)
        }
    }

    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        guard let targetItemID = command.directObject else {
            throw ActionError.internalEngineError("READ command reached process without direct object.")
        }
        guard let targetItem = await engine.item(with: targetItemID) else {
            throw ActionError.internalEngineError("Target item '\(targetItemID)' disappeared between validate and process.")
        }

        // --- State Change: Mark as Touched ---
        var stateChanges: [StateChange] = []
        let initialProperties = targetItem.properties // Use initial state
        if !initialProperties.contains(.touched) {
            stateChanges.append(StateChange(
                entityId: .item(targetItemID),
                propertyKey: .itemProperties,
                oldValue: .itemProperties(initialProperties),
                newValue: .itemProperties(initialProperties.union([.touched]))
            ))
        }

        // --- Determine Message ---
        let message: String
        if let textToRead = targetItem.readableText, !textToRead.isEmpty {
            message = textToRead
        } else {
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
