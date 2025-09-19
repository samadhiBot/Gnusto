import Foundation

/// Handles the SING verb for singing, humming, or making musical sounds.
///
/// This is a humorous atmospheric command that provides entertaining responses
/// to player attempts to sing or make music. Based on ZIL tradition.
public struct SingActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb),
        .match(.verb, .to, .directObject),
        .match(.serenade, .directObject),
    ]

    public let synonyms: [Verb] = [.sing, .hum]

    public let requiresLight: Bool = false

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "SING" command.
    ///
    /// This action provides humorous responses to player attempts to sing or make music.
    /// A classic atmospheric command from ZIL traditions.
    public func process(context: ActionContext) async throws -> ActionResult {
        if let item = try await context.itemDirectObject() {
            return await ActionResult(
                item.response(
                    object: { context.msg.singToObject(context.command, item: $0) },
                    character: { context.msg.singToCharacter(context.verb, character: $0) },
                    enemy: { context.msg.singToEnemy(context.verb, enemy: $0) },
                ),
                item.setFlag(.isTouched)
            )
        }

        return ActionResult(
            context.msg.sing(context.verb)
        )
    }
}
