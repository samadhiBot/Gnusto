import Foundation

/// Handles the "ASK" command for asking characters about topics.
/// Implements communication mechanics following ZIL patterns for character interaction.
/// Supports both direct asking ("ASK TROLL ABOUT TREASURE") and two-phase asking
/// ("ASK TROLL" → "What do you want to ask the troll about?" → "TREASURE").
public struct AskActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject),
        .match(.ask, .about, .indirectObject),
        .match(.inquire, .about, .indirectObject),
        .match(.verb, .directObject, .about, .indirectObject),
    ]

    public let synonyms: [Verb] = [.ask, .question]

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
    public func process(context: ActionContext) async throws -> ActionResult {
        // Handle different syntax patterns:
        // 1. "ask wizard" - character in directObject, no topic
        // 2. "ask about crystal" - topic in indirectObject, no character
        // 3. "ask wizard about crystal" - character in directObject, topic in indirectObject

        let character = try await context.itemDirectObject()
        let topic = context.command.indirectObject

        // Case 1: "ask wizard about crystal" - both character and topic
        if let character, let topic {
            guard await character.isCharacter else {
                throw await ActionResponse.feedback(
                    context.msg.cannotAskAboutThat(character.withDefiniteArticle)
                )
            }
            return try await processDirectAsk(
                character: character,
                topic: topic,
                in: context
            )
        }

        // Case 2: "ask wizard" - character only, prompt for topic
        if let character, topic == nil {
            guard await character.isCharacter else {
                throw await ActionResponse.feedback(
                    context.msg.cannotAskAboutThat(character.withDefiniteArticle)
                )
            }
            return try await promptForTopic(
                character: character,
                in: context
            )
        }

        // Case 3: "ask about crystal" - topic only, no character specified
        throw ActionResponse.feedback(
            context.msg.askWhom()
        )
    }

    // MARK: - Private Helpers

    /// Processes a direct ask command where both character and topic are specified.
    private func processDirectAsk(
        character: ItemProxy,
        topic: ProxyReference,
        in context: ActionContext
    ) async throws -> ActionResult {
        // Default response - games can override with ItemEventHandlers
        await ActionResult(
            context.msg.characterDoesNotSeemToKnow(
                character.withDefiniteArticle,
                topic: topic.withDefiniteArticle
            ),
            character.setFlag(.isTouched)
        )
    }

    /// Prompts the player to specify what topic they want to ask about.
    private func promptForTopic(
        character: ItemProxy,
        in context: ActionContext
    ) async throws -> ActionResult {
        let prompt = "What do you want to ask \(await character.withDefiniteArticle) about?"

        let questionResult = await context.engine.conversationManager.askForTopic(
            question: prompt,
            characterID: character.id,
            context: context
        )

        return await ActionResult(
            message: questionResult.message,
            changes: questionResult.changes + [
                character.setFlag(.isTouched)
            ],
            effects: questionResult.effects
        )
    }
}
