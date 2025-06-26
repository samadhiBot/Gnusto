import Foundation

/// Handles the "LISTEN" command, providing a generic response.
///
/// By default, listening doesn't produce any specific information. Game developers can
/// customize listening behavior by providing custom `ItemEventHandler` or
/// `LocationEventHandler` implementations for specific items or locations if special
/// sounds should be heard.
public struct ListenActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb),
        .match(.verb, .to, .directObject),
    ]

    public let verbs: [VerbID] = [.listen]

    public let requiresLight: Bool = false

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "LISTEN" command.
    ///
    /// This action provides atmospheric responses to listening. Can be used without objects
    /// for general listening, or with objects for listening to specific items.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        if let directObjectRef = command.directObject {
            // Listening to something specific
            guard case .item(let targetItemID) = directObjectRef else {
                throw ActionResponse.prerequisiteNotMet(
                    engine.messenger.cannotDoThat(verb: "listen")
                )
            }

            let targetItem = try await engine.item(targetItemID)
            guard await engine.playerCanReach(targetItemID) else {
                throw ActionResponse.itemNotAccessible(targetItemID)
            }

            return ActionResult(
                "🤡 engine.messenger.listenToSomething(target: targetItem.withDefiniteArticle)",
                await engine.setFlag(.isTouched, on: targetItem),
                await engine.updatePronouns(to: targetItem)
            )
        } else {
            // General listening
            return ActionResult(
                engine.messenger.youHearNothingUnusual()
            )
        }
    }
}
