import Foundation

/// Handles the "THINK ABOUT" command, allowing the player to ponder an item or themselves.
/// This is a more introspective action, often resulting in a generic or humorous response.
public struct ThinkActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.consider, .directObject),
        .match(.ponder, .over, .directObject),
        .match(.think, .about, .directObject),
    ]

    public let requiresLight: Bool = false

    // MARK: - Action Processing Methods

    /// Validates the "THINK ABOUT" command.
    ///
    /// This method ensures that:
    /// 1. A direct object is specified (the player must indicate *what* to think about).
    /// 2. If the direct object is an item, it must exist and be reachable by the player.
    /// 3. Currently, thinking about locations is not supported by this default handler.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: `ActionResponse.custom` if no direct object is provided,
    ///           `ActionResponse.prerequisiteNotMet` if trying to think about a location,
    ///           `ActionResponse.itemNotAccessible` if an item direct object cannot be reached,
    ///           or errors from `engine.item()` if the item doesn't exist.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {

        // 1. Ensure we have a direct object
        guard let directObjectRef = command.directObject else {
            throw ActionResponse.custom(
                engine.messenger.doWhat(action: "think about")
            )
        }

        switch directObjectRef {
        case .player:
            return  // Thinking about self is always valid.
        case .item(let targetItemID):
            // 2. Check if item exists
            let _ = try await engine.item(targetItemID)  // Will throw if not found
            // 3. Check reachability
            guard await engine.playerCanReach(targetItemID) else {
                throw ActionResponse.itemNotAccessible(targetItemID)
            }
        case .location:
            // For now, only allow thinking about items or the player.
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.thinkAboutLocation()
            )
        }
    /// Processes the "THINK ABOUT" command.
    ///
    /// Assuming validation has passed:
    /// - If thinking about the player ("THINK ABOUT SELF"), a humorous message is returned.
    /// - If thinking about an item, the item is marked with the `.isTouched` flag (if not already set),
    ///   pronouns are updated to refer to this item, and a generic message about contemplation
    ///   is returned.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` with a message reflecting the player's thoughts and any
    ///   relevant `StateChange`s (e.g., setting `.isTouched`, updating pronouns).
    /// - Throws: `ActionResponse.internalEngineError` if the direct object is unexpectedly nil,
    ///           or errors from `engine.item()` if an item doesn't exist.
        guard let directObjectRef = command.directObject else {
            // Should be caught by validate.
            throw ActionResponse.internalEngineError("ThinkAbout: directObject was nil in process.")
        }

        switch directObjectRef {
        case .player:
            return ActionResult(
                engine.messenger.thinkAboutSelf()
            )
        case .item(let targetItemID):
            let targetItem = try await engine.item(targetItemID)
            return ActionResult(
                engine.messenger.thinkAboutItem(item: targetItem.withDefiniteArticle),
                await engine.setFlag(.isTouched, on: targetItem),
                await engine.updatePronouns(to: targetItem)
            )
        case .location:
            // Should be caught by validate if we decide not to support thinking about locations.
            // If supported, a custom message would go here.
            return ActionResult(
                engine.messenger.thinkAboutLocation()
            )
        }
    }
}
