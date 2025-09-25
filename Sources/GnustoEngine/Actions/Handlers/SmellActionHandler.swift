import Foundation

/// Handles the "SMELL" command, providing a generic response when the player attempts
/// to smell their surroundings or a specific item.
///
/// By default, smelling the environment or a generic item doesn't reveal anything specific.
/// Game developers can provide more detailed smell descriptions for particular items or
/// locations by implementing custom `ItemEventHandler` or `LocationEventHandler` logic.
public struct SmellActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb),
        .match(.verb, .directObject),
    ]

    public let synonyms: [Verb] = [.smell, .sniff]

    public let requiresLight: Bool = false

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "SMELL" command.
    ///
    /// This action provides olfactory responses to smelling. Can be used without objects
    /// for general environmental smelling, or with objects for smelling specific items.
    public func process(context: ActionContext) async throws -> ActionResult {
        // Smell requires a direct object (what to smell)
        guard
            let item = try await context.itemDirectObject(
                playerMessage: context.msg.smellSelf(context.verb),
                failureMessage: context.msg.smellNothingUnusual(context.verb)
            )
        else {
            throw ActionResponse.feedback(
                context.msg.smellNothingUnusual(context.verb)
            )
        }

        return await ActionResult(
            item.response(
                object: { context.msg.smellObject(context.verb, item: $0) },
                character: { context.msg.smellCharacter(context.verb, character: $0) },
                enemy: { context.msg.smellEnemy(context.verb, enemy: $0) },
            ),
            item.setFlag(.isTouched)
        )
    }
}
