import Foundation

/// Handles the "KISS" command for kissing objects or characters.
/// Implements kissing mechanics following ZIL patterns for social interactions.
public struct KissActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject)
    ]

    public let verbs: [Verb] = [.kiss]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "KISS" command.
    ///
    /// This action validates prerequisites and handles kissing attempts on different types
    /// of objects and characters. Generally provides humorous or appropriate responses
    /// following ZIL traditions.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        // Kiss requires a direct object (what to kiss)
        guard let directObjectRef = command.directObject else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.doWhat(verb: command.verb)
            )
        }

        // Handle kissing self
        if case .player = directObjectRef {
            return ActionResult(
                engine.messenger.kissSelf()
            )
        }

        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.cannotDoThat(verb: "kiss")
            )
        }

        // Check if target exists and is reachable
        let targetItem = try await engine.item(targetItemID)
        guard await engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }

        // Determine appropriate response based on object type
        let message =
            // Kissing characters
            if targetItem.hasFlag(.isCharacter) {
                if targetItem.hasFlag(.isFighting) {
                    engine.messenger.kissEnemy(enemy: targetItem.withDefiniteArticle)
                } else {
                    engine.messenger.kissCharacter(character: targetItem.withDefiniteArticle)
                }
            } else {
                // Kissing objects - generic response
                engine.messenger.kissObject(item: targetItem.withDefiniteArticle)
            }

        return ActionResult(
            message,
            await engine.setFlag(.isTouched, on: targetItem),
            await engine.updatePronouns(to: targetItem)
        )
    }
}
