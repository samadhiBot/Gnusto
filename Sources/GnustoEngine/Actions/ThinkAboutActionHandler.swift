import Foundation

/// Action handler for the THINK ABOUT verb (based on Cloak of Darkness).
public struct ThinkAboutActionHandler: EnhancedActionHandler {

    public init() {}

    // MARK: - EnhancedActionHandler Methods

    public func validate(command: Command, engine: GameEngine) async throws {
        // 1. Ensure we have a direct object
        guard let targetItemID = command.directObject else {
            throw ActionError.customResponse("Think about what?")
        }

        // 2. Skip further checks if thinking about self (PLAYER)
        if targetItemID.rawValue == "player" { return }

        // 3. Check if item exists
        guard await engine.itemSnapshot(with: targetItemID) != nil else {
            throw ActionError.internalEngineError("Parser resolved non-existent item ID '\(targetItemID)'.")
        }

        // 4. Check reachability
        let isReachable = await engine.scopeResolver.itemsReachableByPlayer().contains(targetItemID)
        guard isReachable else {
            throw ActionError.itemNotAccessible(targetItemID)
        }
    }

    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        guard let targetItemID = command.directObject else {
            // Should be caught by validate
            throw ActionError.internalEngineError("THINK ABOUT command reached process without direct object.")
        }

        let message: String
        var stateChanges: [StateChange] = []

        // Handle thinking about player
        if targetItemID.rawValue == "player" {
            message = "Yes, yes, you're very important."
        } else {
            // Handle thinking about an item
            guard let targetItem = await engine.itemSnapshot(with: targetItemID) else {
                 // Should be caught by validate
                throw ActionError.internalEngineError("Target item '\(targetItemID)' disappeared between validate and process.")
            }

            // Mark as touched if not already
            if !targetItem.hasProperty(.touched) {
                let change = StateChange(
                    entityId: .item(targetItemID),
                    propertyKey: .itemProperties,
                    oldValue: .itemProperties(targetItem.properties),
                    newValue: .itemProperties(targetItem.properties.union([.touched]))
                )
                stateChanges.append(change)
            }

            // Set the standard message
            message = "You contemplate the \(targetItem.name) for a bit, but nothing fruitful comes to mind."
        }

        // Create result
        return ActionResult(
            success: true,
            message: message,
            stateChanges: stateChanges
        )
    }
}
