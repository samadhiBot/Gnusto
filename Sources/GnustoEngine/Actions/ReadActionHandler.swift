import Foundation

/// Handles the "READ" context.command.
public struct ReadActionHandler: EnhancedActionHandler {

    public init() {}

    // MARK: - EnhancedActionHandler Methods

    public func validate(context: ActionContext) async throws {
        // 1. Ensure we have a direct object
        guard let targetItemID = context.command.directObject else {
            throw ActionError.customResponse("Read what?")
        }

        // 2. Check if item exists
        guard let targetItem = await context.engine.item(targetItemID) else {
            throw ActionError.internalEngineError("Parser resolved non-existent item ID '\(targetItemID)'.")
        }

        // 3. Check reachability
        let currentLocationID = await context.engine.gameState.player.currentLocationID
        let itemParent = targetItem.parent
        var isReachable = false
        switch itemParent {
        case .location(let locID):
            isReachable = (locID == currentLocationID)
        case .item(let parentItemID):
            guard let parentItem = await context.engine.item(parentItemID) else {
                throw ActionError.internalEngineError("Item \(targetItemID) references non-existent parent item \(parentItemID).")
            }
            let parentParent = parentItem.parent
            // Check if parent is in current location or held by player
            let isParentItemInReach = (parentParent == .location(currentLocationID) || parentParent == .player)
            if isParentItemInReach {
                // Check if parent allows access (surface or open container)
                let isParentContainer = parentItem.hasFlag(.isContainer)
                let isParentOpen: Bool = try await context.engine.fetch(parentItemID, .isOpen)
                if parentItem.hasFlag(.isSurface) || (isParentContainer && isParentOpen) {
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
        let isLit = await context.engine.scopeResolver.isLocationLit(locationID: currentLocationID)
        let providesLight = targetItem.hasFlag(.isLightSource) && targetItem.hasFlag(.isOn)
        guard isLit || providesLight else {
            throw ActionError.roomIsDark
        }

        // 5. Check if item is readable
        guard targetItem.hasFlag(.isReadable) else {
            throw ActionError.itemNotReadable(targetItemID)
        }
    }

    public func process(context: ActionContext) async throws -> ActionResult {
        guard let targetItemID = context.command.directObject else {
            throw ActionError.internalEngineError("READ context.command reached process without direct object.")
        }
        guard let targetItem = await context.engine.item(targetItemID) else {
            throw ActionError.internalEngineError("Target item '\(targetItemID)' disappeared between validate and process.")
        }

        // --- State Change: Mark as Touched ---
        var stateChanges: [StateChange] = []
        if targetItem.attributes[.isTouched] != true {
            stateChanges.append(StateChange(
                entityID: .item(targetItemID),
                attributeKey: .itemAttribute(.isTouched),
                oldValue: targetItem.attributes[.isTouched] ?? false,
                newValue: true,
            ))
        }

        // --- Determine Message ---
        let message: String
        // Fetch text from dynamic values
        let textToRead: String = try await context.engine.fetch(targetItemID, .readText)
        if textToRead.isEmpty {
            message = "There's nothing written on the \(targetItem.name)."
        } else {
            message = textToRead
        }

        // --- Create Result ---
        return ActionResult(
            success: true,
            message: message,
            stateChanges: stateChanges
        )
    }
}
