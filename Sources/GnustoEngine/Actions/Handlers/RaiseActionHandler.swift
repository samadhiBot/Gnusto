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

    public let verbs: [VerbID] = [.raise, .lift, .hoist]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    /// Validates that the action can be performed.
    ///
    /// - Parameter context: The `ActionContext` containing the command and game state.
    /// - Returns: An `ActionResult` indicating validation success or failure.
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
        guard (try? await engine.item(targetItemID)) != nil else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }

        guard await engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }
    /// Processes the raise action.
    ///
    /// - Parameter context: The `ActionContext` containing the command and game state.
    /// - Returns: An `ActionResult` with the action outcome.
        guard case .item(let targetItemID) = command.directObject else {
            throw ActionResponse.internalEngineError(
                "Raise: directObject was not an item in process."
            )
        }

        let targetItem = try await engine.item(targetItemID)

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
