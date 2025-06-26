import Foundation

/// Handles the CHOMP verb for biting, gnawing, or chewing actions.
///
/// This is a humorous command that provides entertaining responses to player attempts
/// to bite or chew on things. Based on ZIL tradition of atmospheric commands.
public struct ChompActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject),
        .match(.verb),
    ]

    public let verbs: [Verb] = [.chomp, .bite, .chew]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "CHOMP" command.
    ///
    /// This action provides humorous responses to player attempts to bite or chew things.
    /// Can be used with or without a target object.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        if let directObjectRef = command.directObject {
            // Chomping on something
            guard case .item(let targetItemID) = directObjectRef else {
                throw ActionResponse.prerequisiteNotMet(
                    engine.messenger.thatsNotSomethingYouCan(.chomp)
                )
            }

            // Check if item exists and is accessible
            let targetItem = try await engine.item(targetItemID)
            guard await engine.playerCanReach(targetItemID) else {
                throw ActionResponse.itemNotAccessible(targetItemID)
            }

            // Special responses for different types of items
            let message =
                if targetItem.hasFlag(.isEdible) {
                    engine.messenger.chompEdible(
                        item: targetItem.withIndefiniteArticle
                    )
                } else if targetItem.hasFlag(.isPerson) || targetItem.hasFlag(.isCharacter) {
                    engine.messenger.chompCharacter(
                        targetItem.withDefiniteArticle
                    )
                } else {
                    engine.messenger.chompTargetResponse(
                        item: targetItem.withDefiniteArticle
                    )
                }

            return ActionResult(
                message,
                await engine.setFlag(.isTouched, on: targetItem),
                await engine.updatePronouns(to: targetItem)
            )
        } else {
            // General chomping (no object)
            return ActionResult(
                engine.messenger.chompResponse()
            )
        }
    }
}
