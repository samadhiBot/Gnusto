import Foundation

/// Action handler for the THINK ABOUT verb (based on Cloak of Darkness).
public struct ThinkAboutActionHandler: ActionHandler {

    public init() {}

    public func perform(command: Command, engine: GameEngine) async throws {
        // 1. Ensure we have a direct object
        guard let targetItemID = command.directObject else {
            // No specific prompt in CoD ZIL, invent one.
            await engine.ioHandler.print("Think about what?")
            return
        }

        // 2. Check if thinking about self (PLAYER)
        // Use the conventional ItemID "player"
        if targetItemID.rawValue == "player" { // Check rawValue against string
            // CoD message: "Yes, yes, you're very important."
            await engine.ioHandler.print("Yes, yes, you're very important.")
            return
        }

        // 3. Check if item exists and is accessible
        // (Standard reachability check)
        guard let targetItem = await engine.itemSnapshot(with: targetItemID) else {
            throw ActionError.internalEngineError("Parser resolved non-existent item ID '\(targetItemID)'.")
        }

        let isReachable = await engine.scopeResolver.itemsReachableByPlayer().contains(targetItemID)
        guard isReachable else {
            // Use standard error for inaccessible items
            throw ActionError.itemNotAccessible(targetItemID)
        }

        // Item is accessible, mark as touched?
        // CoD ZIL doesn't explicitly set TOUCHBIT here, but it's harmless.
        await engine.applyItemPropertyChange(itemID: targetItemID, adding: [.touched])

        // 4. Output default message
        // CoD message: "You contemplate the {object} for a bit, but nothing fruitful comes to mind."
        await engine.ioHandler.print("You contemplate the \(targetItem.name) for a bit, but nothing fruitful comes to mind.")
    }
}
