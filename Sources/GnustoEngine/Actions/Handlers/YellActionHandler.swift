import Foundation

/// Handles the YELL verb for yelling, shouting, or making loud vocalizations.
///
/// This is a humorous atmospheric command that provides entertaining responses
/// to player attempts to yell or shout. Based on ZIL tradition.
public struct YellActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb),
        .match(.verb, .at, .directObject),
    ]

    public let verbs: [VerbID] = [.yell, .shout, .scream, .shriek, .holler]

    public let requiresLight: Bool = false

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "YELL" command.
    ///
    /// This action provides humorous responses to player attempts to yell or shout.
    /// Can be used with or without a target object.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        if let directObjectRef = command.directObject {
            // Yelling at something/someone
            guard case .item(let targetItemID) = directObjectRef else {
                throw ActionResponse.prerequisiteNotMet(
                    engine.messenger.cannotDoThat(verb: "yell")
                )
            }

            let targetItem = try await engine.item(targetItemID)
            guard await engine.playerCanReach(targetItemID) else {
                throw ActionResponse.itemNotAccessible(targetItemID)
            }

            return ActionResult(
                engine.messenger.yellAtSomething(target: targetItem.withDefiniteArticle),
                await engine.setFlag(.isTouched, on: targetItem),
                await engine.updatePronouns(to: targetItem)
            )
        } else {
            // General yelling
            return ActionResult(
                engine.messenger.yellResponse()
            )
        }
    }
}
