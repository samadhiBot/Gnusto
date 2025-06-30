import Foundation

/// Handles the "ASK" command for asking characters about topics.
/// Implements communication mechanics following ZIL patterns for character interaction.
/// Supports both direct asking ("ASK TROLL ABOUT TREASURE") and two-phase asking
/// ("ASK TROLL" → "What do you want to ask the troll about?" → "TREASURE").
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
    /// Handles asking characters about topics in two modes:
    /// 1. Direct asking: "ASK TROLL ABOUT TREASURE" - processes immediately
    /// 2. Two-phase asking: "ASK TROLL" - prompts for topic, then processes response
    ///
    /// Game-specific ItemEventHandlers can provide custom dialogue responses.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        guard let characterID = command.directObjectItemID else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.askWhom()
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

        // Check if we have an indirect object (topic) specified
        if let indirectObjectRef = command.indirectObject {
            // Direct asking - we have both character and topic
            return try await processDirectAsk(
                character: character,
                characterID: characterID,
                topic: indirectObjectRef,
                engine: engine
            )
        } else {
            // Two-phase asking - prompt for topic
            return await promptForTopic(
                character: character,
                characterID: characterID,
                command: command,
                engine: engine
            )
        }
    }

    // MARK: - Private Helpers

    /// Processes a direct ask command where both character and topic are specified.
    private func processDirectAsk(
        character: Item,
        characterID: ItemID,
        topic: EntityReference,
        engine: GameEngine
    ) async throws -> ActionResult {
        let topicDescription: String
        switch topic {
        case .item(let topicItemID):
            let topicItem = try await engine.item(topicItemID)
            topicDescription = topicItem.withIndefiniteArticle
        case .player:
            topicDescription = engine.messenger.you()
        case .location(let locationID):
            let location = try await engine.location(locationID)
            topicDescription = location.withDefiniteArticle
        case .universal(let universal):
            topicDescription = "the \(universal)"
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

    /// Prompts the player to specify what topic they want to ask about.
    private func promptForTopic(
        character: Item,
        characterID: ItemID,
        command: Command,
        engine: GameEngine
    ) async -> ActionResult {
        let prompt = "What do you want to ask \(character.withDefiniteArticle) about?"

        let questionChanges = await ConversationManager.askForTopic(
            prompt: prompt,
            characterID: characterID,
            originalCommand: command,
            engine: engine
        )

        return ActionResult(
            message: prompt,
            changes: questionChanges + [
                await engine.setFlag(.isTouched, on: character),
                await engine.updatePronouns(to: character),
            ]
        )
    }
}
