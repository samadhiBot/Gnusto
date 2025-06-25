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

    /// Validates the "TELL" command.
    ///
    /// This method ensures that:
    /// 1. Both direct and indirect objects are specified (who to tell and what to tell about).
    /// 2. The direct object (who to tell) is a character.
    /// 3. The character is present and reachable.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: Various `ActionResponse` errors if validation fails.
        public func process(
        command: Command,
        engine: GameEngine
    ) async throws -> ActionResult {

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

        guard command.indirectObject != nil else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.tellCharacterAboutWhat(character: character.withDefiniteArticle)
            )
        }
    /// Processes the "TELL" command.
    ///
    /// Handles telling characters about topics. By default, most characters
    /// don't have specific responses, but game-specific ItemEventHandlers
    /// can provide custom dialogue.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` with appropriate dialogue response and state changes.
        guard let directObjectRef = command.directObject,
            case .item(let characterID) = directObjectRef,
            let indirectObjectRef = command.indirectObject
        else {
            throw ActionResponse.internalEngineError(
                "TellActionHandler: missing required objects in process."
            )
        }

        let character = try await engine.item(characterID)

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
            await engine.updatePronouns(to: character),
        )
    }
}
