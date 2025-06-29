import Foundation

/// Handles the DANCE verb for dancing, boogieing, or expressing joy through movement.
///
/// This is a humorous atmospheric command that provides entertaining responses
/// to player attempts to dance. Based on ZIL tradition, including the classic
/// "Dancing is forbidden" response from Cloak of Darkness.
public struct DanceActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb),
        .match(.verb, .with, .directObject),
    ]

    public let verbs: [Verb] = [.dance]

    public let requiresLight: Bool = false

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "DANCE" command.
    ///
    /// This action provides humorous responses to player attempts to dance.
    /// Can be used with or without a dance partner.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        guard let directObjectRef = command.directObject else {
            // General dancing
            return ActionResult(
                engine.messenger.danceResponse()
            )
        }

        // Dancing with something/someone
        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.cannotDoThat(verb: "dance")
            )
        }

        let targetItem = try await engine.item(targetItemID)

        guard await engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }

        let message = if targetItem.hasFlag(.isCharacter) {
            if targetItem.hasFlag(.isFighting) {
                engine.messenger.danceWith(enemy: targetItem.withDefiniteArticle)
            } else {
                engine.messenger.danceWith(partner: targetItem.withDefiniteArticle)
            }
        } else {
            engine.messenger.danceWith(item: targetItem.withDefiniteArticle)
        }

        return ActionResult(
            message,
            await engine.setFlag(.isTouched, on: targetItem),
            await engine.updatePronouns(to: targetItem)
        )
    }
}
