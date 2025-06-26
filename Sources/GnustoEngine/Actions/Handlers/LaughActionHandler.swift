import Foundation

/// Handles the LAUGH verb for laughing, guffawing, or expressing mirth.
///
/// This is a humorous atmospheric command that provides entertaining responses
/// to player attempts to laugh. Based on ZIL tradition.
public struct LaughActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb),
        .match(.verb, .at, .directObject),
    ]

    public let verbs: [VerbID] = [.laugh, .chuckle, .giggle, .snicker, .chortle]

    public let requiresLight: Bool = false

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "LAUGH" command.
    ///
    /// This action provides humorous responses to player attempts to laugh.
    /// Can be used with or without a target object.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        if let directObjectRef = command.directObject {
            // Laughing at something/someone
            guard case .item(let targetItemID) = directObjectRef else {
                throw ActionResponse.prerequisiteNotMet(
                    engine.messenger.cannotDoThat(verb: "laugh")
                )
            }

            let targetItem = try await engine.item(targetItemID)
            guard await engine.playerCanReach(targetItemID) else {
                throw ActionResponse.itemNotAccessible(targetItemID)
            }

            return ActionResult(
                "🤡 engine.messenger.laughAtSomething(target: targetItem.withDefiniteArticle)",
//                engine.messenger.laughAtSomething(target: targetItem.withDefiniteArticle),
                await engine.setFlag(.isTouched, on: targetItem),
                await engine.updatePronouns(to: targetItem)
            )
        } else {
            // General laughing
            return ActionResult(
                engine.messenger.laughResponse()
            )
        }
    }
}
