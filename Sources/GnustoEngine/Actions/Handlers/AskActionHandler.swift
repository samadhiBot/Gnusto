import Foundation

/// Handles the "ASK" command for asking characters about topics.
/// Implements communication mechanics following ZIL patterns for character interaction.
public struct AskActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject),
        .match(.verb, .directObject, .about, .indirectObject),
    ]

    public let verbs: [Verb] = [.ask, .question]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "ASK" command.
    ///
    /// Handles asking characters about topics. By default, most characters
    /// don't have specific responses, but game-specific ItemEventHandlers
    /// can provide custom dialogue.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        guard let characterID = command.directObjectItemID else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.askWhom()
            )
        }

        guard let indirectObjectRef = command.indirectObject else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.doWhat(verb: command.verb)
            )
        }

        let character = try await engine.item(characterID)

        guard character.hasFlag(.isCharacter) else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.cannotAskAboutThat(item: character.withDefiniteArticle)
            )
        }

        guard await engine.playerCanReach(characterID) else {
            throw ActionResponse.itemNotAccessible(characterID)
        }

        let topicDescription: String
        switch indirectObjectRef {
        case .item(let topicItemID):
            let topicItem = try await engine.item(topicItemID)
            topicDescription = topicItem.withIndefiniteArticle
        case .player:
            topicDescription = engine.messenger.you()
        case .location(let locationID):
            let location = try await engine.location(locationID)
            topicDescription = engine.messenger.anySomething(location.name)
        }

        // Default response - games can override with ItemEventHandlers
        return ActionResult(
            engine.messenger.characterDoesNotSeemToKnow(
                character: character.withDefiniteArticle,
                topic: topicDescription
            ),
            await engine.setFlag(.isTouched, on: character),
            await engine.updatePronouns(to: character)
        )
    }
}
