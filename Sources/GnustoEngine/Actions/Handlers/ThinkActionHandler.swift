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

    public let verbs: [Verb] = [.think, .consider, .ponder]

    public let requiresLight: Bool = false

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "THINK ABOUT" command.
    ///
    /// This action validates prerequisites and provides contemplative responses for thinking
    /// about objects or the player themselves. Items are marked as touched when thought about.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        // Ensure we have a direct object
        guard let directObjectRef = command.directObject else {
            throw ActionResponse.custom(
                engine.messenger.doWhat(action: "think about")
            )
        }

        switch directObjectRef {
        case .player:
            return ActionResult(
                engine.messenger.thinkAboutSelf()
            )

        case .item(let targetItemID):
            // Check if item exists and is accessible
            let targetItem = try await engine.item(targetItemID)
            guard await engine.playerCanReach(targetItemID) else {
                throw ActionResponse.itemNotAccessible(targetItemID)
            }

            return ActionResult(
                engine.messenger.thinkAboutItem(item: targetItem.withDefiniteArticle),
                await engine.setFlag(.isTouched, on: targetItem),
                await engine.updatePronouns(to: targetItem)
            )

        case .location:
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.thinkAboutLocation()
            )
        }
    }
}
