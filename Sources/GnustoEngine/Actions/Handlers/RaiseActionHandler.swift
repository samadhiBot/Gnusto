import Foundation

/// Handles the RAISE verb (synonym: LIFT).
///
/// The ZIL equivalent is the `V-RAISE` routine. This action represents the player
/// attempting to lift or raise an object.
public struct RaiseActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject)
    ]

    public let verbs: [Verb] = [.raise, .lift, .hoist]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the raise action.
    ///
    /// - Parameter command: The command being processed.
    /// - Parameter engine: The game engine.
    /// - Returns: An `ActionResult` with the action outcome.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        guard let directObjectRef = command.directObject else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.doWhat(verb: command.verb)
            )
        }

        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.thatsNotSomethingYouCan(.raise)
            )
        }

        // Check if item exists and is reachable
        let targetItem = try await engine.item(targetItemID)

        guard await engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }

        // Default behavior: You can't raise most things
        return ActionResult(
            engine.messenger.raiseCannotLift(
                item: targetItem.withDefiniteArticle
            ),
            await engine.setFlag(.isTouched, on: targetItem),
            await engine.updatePronouns(to: targetItem)
        )
    }
}
