import Foundation

/// Handles the "TIE" command for tying objects together.
/// Implements tying mechanics following ZIL patterns for object binding and connection.
public struct TieActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject),
        .match(.tie, .up, .directObject),
        .match(.verb, .directObject, .to, .indirectObject),
        .match(.verb, .directObject, .with, .indirectObject),
        .match(.tie, .up, .directObject, .with, .indirectObject),
    ]

    public let synonyms: [Verb] = [.tie, .fasten, .bind]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "TIE" command.
    ///
    /// Handles tying attempts on different types of objects.
    /// Can tie objects together or just tie objects in general.
    public func process(context: ActionContext) async throws -> ActionResult {
        // Tie requires a direct object (what to tie)
        guard let recipient = try await context.itemDirectObject() else {
            throw ActionResponse.doWhat(context)
        }

        guard let apparatus = try await context.itemIndirectObject() else {
            // General tying/binding - no specific target
            return await ActionResult(
                recipient.response(
                    object: { context.msg.tieItem(context.command, item: $0) },
                    character: { context.msg.tieCharacter(context.command, character: $0) },
                    enemy: { context.msg.tieEnemy(context.command, enemy: $0) }
                ),
                recipient.setFlag(.isTouched)
            )
        }

        // If a target is specified, validate it
        let theApparatus = await apparatus.withDefiniteArticle

        switch context.command.preposition {
        case .to:
            guard apparatus != recipient else {
                throw ActionResponse.feedback(
                    context.msg.tieItemToItself(context.command, item: theApparatus)
                )
            }

            return await ActionResult(
                apparatus.response(
                    object: {
                        context.msg.tieItemTo(context.command, item: $0, to: theApparatus)
                    },
                    character: { context.msg.tieCharacter(context.command, character: $0) },
                    enemy: { context.msg.tieEnemy(context.command, enemy: $0) },
                ),
                recipient.setFlag(.isTouched),
                apparatus.setFlag(.isTouched)
            )

        default:  // case .with:
            guard apparatus != recipient else {
                throw ActionResponse.feedback(
                    context.msg.tieItemWithItself(context.command, item: theApparatus)
                )
            }

            return await ActionResult(
                recipient.response(
                    object: {
                        context.msg.tieItemWith(context.command, item: $0, with: theApparatus)
                    },
                    character: { context.msg.tieCharacter(context.command, character: $0) },
                    enemy: { context.msg.tieEnemy(context.command, enemy: $0) },
                ),
                recipient.setFlag(.isTouched),
                apparatus.setFlag(.isTouched)
            )
        }
    }
}
