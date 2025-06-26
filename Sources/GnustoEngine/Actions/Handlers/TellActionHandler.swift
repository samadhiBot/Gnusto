import Foundation

/// Handles the "TELL" command for telling characters about topics.
/// Implements communication mechanics following ZIL patterns for character interaction.
public struct TellActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject),
        .match(.verb, .directObject, .about, .indirectObject),
    ]

    public let verbs: [VerbID] = [.tell, .inform]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "TELL" command.
    ///
    /// Handles telling characters about topics. By default, most characters
    /// don't have specific responses, but game-specific ItemEventHandlers
    /// can provide custom dialogue.
    ///
    /// - Parameter command: The command being processed.
    /// - Parameter engine: The game engine.
    /// - Returns: An `ActionResult` with appropriate dialogue response and state changes.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        // TELL requires both direct object (who) and indirect object (what about)
        guard let directObjectRef = command.directObject else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.tellWhom()
            )
        }

        guard case .item(let characterID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.tellCanOnlyTellCharacters()
            )
        }

        // Check if character exists and is reachable
        let character = try await engine.item(characterID)

        guard character.hasFlag(.isCharacter) else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.tellCannotTellAbout(item: character.withDefiniteArticle)
            )
        }

        guard await engine.playerCanReach(characterID) else {
            throw ActionResponse.itemNotAccessible(characterID)
        }

        guard let indirectObjectRef = command.indirectObject else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.tellCharacterAboutWhat(character: character.withDefiniteArticle)
            )
        }

        // Determine what's being told about
        let topicDescription: String
        switch indirectObjectRef {
        case .item(let topicItemID):
            let topicItem = try await engine.item(topicItemID)
            topicDescription = topicItem.withDefiniteArticle
        case .player:
            topicDescription = "yourself"
        case .location(let locationID):
            let location = try await engine.location(locationID)
            topicDescription = location.name
        }

        // Default response - games can override with ItemEventHandlers
        return ActionResult(
            engine.messenger.characterListens(
                character: character.withDefiniteArticle,
                topic: topicDescription
            ),
            await engine.setFlag(.isTouched, on: character),
            await engine.updatePronouns(to: character)
        )
    }
}
