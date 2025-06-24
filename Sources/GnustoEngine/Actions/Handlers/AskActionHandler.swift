import Foundation

/// Handles the "ASK" command for asking characters about topics.
/// Implements communication mechanics following ZIL patterns for character interaction.
public struct AskActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject),
        .match(.verb, .directObject, .about, .indirectObject),
    ]

    public let synonyms: [VerbID] = [.ask, .question]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Validates the "ASK" command.
    ///
    /// This method ensures that:
    /// 1. Both direct and indirect objects are specified (who to ask and what to ask about).
    /// 2. The direct object (who to ask) is a character.
    /// 3. The character is present and reachable.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: Various `ActionResponse` errors if validation fails.
    public func validate(context: ActionContext) async throws {
        // ASK requires both direct object (who) and indirect object (what about)
        guard let directObjectRef = context.command.directObject else {
            throw ActionResponse.prerequisiteNotMet(
                context.message.askWhom()
            )
        }
        guard context.command.indirectObject != nil else {
            throw ActionResponse.prerequisiteNotMet(
                context.message.doWhat(verb: context.command.verb)
            )
        }

        guard case .item(let characterID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet(
                context.message.canOnlyActOnCharacters(verb: "ask")
            )
        }

        // Check if character exists and is reachable
        let character = try await context.engine.item(characterID)
        guard character.hasFlag(.isCharacter) else {
            throw ActionResponse.prerequisiteNotMet(
                context.message.cannotAskAboutThat(item: character.withDefiniteArticle)
            )
        }

        guard await context.engine.playerCanReach(characterID) else {
            throw ActionResponse.itemNotAccessible(characterID)
        }
    }

    /// Processes the "ASK" command.
    ///
    /// Handles asking characters about topics. By default, most characters
    /// don't have specific responses, but game-specific ItemEventHandlers
    /// can provide custom dialogue.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` with appropriate dialogue response and state changes.
    public func process(context: ActionContext) async throws -> ActionResult {
        guard
            let directObjectRef = context.command.directObject,
            case .item(let characterID) = directObjectRef,
            let indirectObjectRef = context.command.indirectObject
        else {
            throw ActionResponse.internalEngineError(
                context.message.actionHandlerMissingObjects(handler: "AskActionHandler")
            )
        }

        let character = try await context.engine.item(characterID)

        // Determine what's being asked about
        let topicDescription: String
        switch indirectObjectRef {
        case .item(let topicItemID):
            let topicItem = try await context.engine.item(topicItemID)
            topicDescription = topicItem.withIndefiniteArticle
        case .player:
            topicDescription = "you"
        case .location(let locationID):
            let location = try await context.engine.location(locationID)
            topicDescription = "any \(location.name)"
        }

        // Default response - games can override with ItemEventHandlers
        let message = """
            \(character.name.capitalizedFirst) doesn't seem to know
            anything about \(topicDescription).
            """

        return ActionResult(
            message: message,
            changes: [
                await context.engine.setFlag(.isTouched, on: character),
                await context.engine.updatePronouns(to: character),
            ]
        )
    }
}
