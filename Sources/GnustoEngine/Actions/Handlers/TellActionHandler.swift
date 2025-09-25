import Foundation

/// Handles the "TELL" command for telling characters about topics.
/// Implements communication mechanics following ZIL patterns for character interaction.
public struct TellActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject),
        .match(.talk, .to, .directObject),
        .match(.verb, .directObject, .about, .indirectObject),
        .match(.speak, .to, .directObject, .about, .indirectObject),
        .match(.talk, .to, .directObject, .about, .indirectObject),
        .match(.say, .indirectObject, .to, .directObject),
    ]

    public let synonyms: [Verb] = [.tell, .inform]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "TELL" command.
    ///
    /// Handles telling characters about topics. By default, characters don't have specific
    /// responses, but game-specific ItemEventHandlers can provide custom dialogue.
    ///
    /// - Returns: An `ActionResult` with appropriate dialogue response and state changes.
    public func process(context: ActionContext) async throws -> ActionResult {
        // Handle different syntax patterns:
        // 1. "tell wizard" - character in directObject, no topic
        // 2. "tell about crystal" - topic in indirectObject, no character
        // 3. "tell wizard about crystal" - character in directObject, topic in indirectObject

        let topic = context.command.indirectObject
        let audience = try await context.itemDirectObject(
            playerMessage: context.msg.tellSelfAbout(topic?.withDefiniteArticle),
            failureMessage: context.msg.tellUniverseAbout(topic?.withDefiniteArticle),
        )

        // Case 1: "tell wizard about crystal" - both character and topic
        if let audience, let topic {
            let theTopic = await topic.withDefiniteArticle
            return await ActionResult(
                audience.response(
                    object: { context.msg.tellItemAboutTopic($0, topic: theTopic) },
                    character: { context.msg.tellCharacterAboutTopic($0, topic: theTopic) },
                    enemy: { context.msg.tellEnemyAboutTopic($0, topic: theTopic) },
                ),
                audience.setFlag(.isTouched)
            )
        }

        // Case 2: "tell wizard" - character only, prompt for topic
        if let audience {
            return await ActionResult(
                audience.response(
                    object: context.msg.tellObject,
                    character: context.msg.tellCharacter,
                    enemy: context.msg.tellEnemy,
                ),
                audience.setFlag(.isTouched)
            )
        }

        // Case 3: "tell about crystal" - topic only, no character specified
        throw ActionResponse.feedback(
            context.msg.tellWhom()
        )
    }
}
