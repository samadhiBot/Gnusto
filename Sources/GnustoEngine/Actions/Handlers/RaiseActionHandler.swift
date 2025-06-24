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

    public let synonyms: [VerbID] = [.raise, .lift, .hoist]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    /// Validates that the action can be performed.
    ///
    /// - Parameter context: The `ActionContext` containing the command and game state.
    /// - Returns: An `ActionResult` indicating validation success or failure.
    public func validate(context: ActionContext) async throws {
        guard let directObjectRef = context.command.directObject else {
            throw ActionResponse.prerequisiteNotMet(
                context.message.doWhat(verb: context.command.verb)
            )
        }

        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet(
                context.message.thatsNotSomethingYouCan(.raise)
            )
        }

        // Check if item exists and is reachable
        guard (try? await context.engine.item(targetItemID)) != nil else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }

        guard await context.engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }
    }

    /// Processes the raise action.
    ///
    /// - Parameter context: The `ActionContext` containing the command and game state.
    /// - Returns: An `ActionResult` with the action outcome.
    public func process(context: ActionContext) async throws -> ActionResult {
        guard case .item(let targetItemID) = context.command.directObject else {
            throw ActionResponse.internalEngineError(
                "Raise: directObject was not an item in process."
            )
        }

        let targetItem = try await context.engine.item(targetItemID)

        // Default behavior: You can't raise most things
        return ActionResult(
            message: context.message.raiseCannotLift(
                item: targetItem.withDefiniteArticle
            ),
            changes: [
                await context.engine.setFlag(.isTouched, on: targetItem),
                await context.engine.updatePronouns(to: targetItem),
            ]
        )
    }
}
