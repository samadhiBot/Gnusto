import Foundation

/// Handles the "CHOMP" command for biting, gnawing, or chewing actions.
///
/// This handler manages bite actions with intelligent disambiguation for edible items.
/// When the player chomps on something edible, it asks whether they want to eat it completely
/// or just take a bite. Based on ZIL tradition of atmospheric commands with modern conversation system.
public struct ChompActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject),
        .match(.verb),
    ]

    public let synonyms: [Verb] = [.chomp, .bite, .chew]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "CHOMP" command.
    ///
    /// This action provides responses to player attempts to bite or chew things.
    /// For edible items, it asks for disambiguation between eating completely or just taking a bite.
    /// Can be used with or without a target object.
    public func process(context: ActionContext) async throws -> ActionResult {
        guard let item = try await context.itemDirectObject() else {
            // General chomping (no object)
            return ActionResult(
                context.msg.chomp()
            )
        }

        // Handle edible items with disambiguation
        if await item.hasFlag(.isEdible) {
            // "Do you mean you want to eat {item}?"
            return await context.engine.conversationManager.askYesNo(
                    question: context.msg.doYouWantToEat(item.withDefiniteArticle),
                    yesCommand: Command(
                        verb: .eat,
                        directObject: context.command.directObject
                    ),
                    noMessage: context.msg.chompAbort(),
                    context: context
                )
//            return await YesNoQuestionHandler.askToDisambiguate(
//                question: context.msg.doYouWantToEat(item.withDefiniteArticle),
//                clarifiedCommand: Command(
//                    verb: .eat,
//                    directObject: context.command.directObject
//                ),
//                context: context
//            )
        }

        return try await ActionResult(
            item.response(
                object: context.msg.chompItem,
                character: context.msg.chompCharacter,
                enemy: context.msg.chompEnemy
            ),
            item.setFlag(.isTouched)
        )
    }
}
