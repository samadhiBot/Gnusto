import Foundation

/// Handles the "KICK" command for kicking objects.
/// Implements kicking mechanics following ZIL patterns for physical interactions.
public struct KickActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject)
    ]

    public let verbs: [VerbID] = [.kick]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "KICK" command.
    ///
    /// This action validates prerequisites and handles kicking attempts on different types
    /// of objects. Generally provides humorous or dismissive responses following ZIL traditions.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        // Kick requires a direct object (what to kick)
        guard let directObjectRef = command.directObject else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.doWhat(verb: command.verb)
            )
        }
        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.cannotDoThat(verb: "kick")
            )
        }

        // Check if target exists and is reachable
        let targetItem = try await engine.item(targetItemID)
        guard await engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }

        // Determine appropriate response based on object type
        let message =
            if targetItem.hasFlag(.isCharacter) {
                // Kicking characters is generally not advisable
                engine.messenger.kickCharacter(character: targetItem.withDefiniteArticle)
            } else {
                // Generic kicking response for objects
                engine.messenger.kickLargeObject(item: targetItem.withDefiniteArticle)
            }

        return ActionResult(
            message,
            await engine.setFlag(.isTouched, on: targetItem),
            await engine.updatePronouns(to: targetItem)
        )
    }
}
