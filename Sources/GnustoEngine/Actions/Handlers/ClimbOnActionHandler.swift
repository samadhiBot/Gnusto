import Foundation

/// Handles the CLIMB ON verb (synonyms: SIT ON, STAND ON).
///
/// The ZIL equivalent is the `V-CLIMB-ON` routine. This action represents the player
/// attempting to climb onto or sit on an object.
public struct ClimbOnActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let verbID: VerbID = .climbOn

    public let syntax: [SyntaxRule] = [
        .match(.verb, .on, .directObject),
        .match(.verb, .directObject),
    ]

    public let synonyms: [String] = ["sit on", "mount"]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    /// Validates that the action can be performed.
    ///
    /// - Parameter context: The `ActionContext` containing the command and game state.
    /// - Throws: An `ActionResponse` if validation fails.
    public func validate(context: ActionContext) async throws {
        guard let directObjectRef = context.command.directObject else {
            throw ActionResponse.prerequisiteNotMet(
                context.message.doWhat(verb: .climbOn)
            )
        }

        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet(
                context.message.cannotDoThat(verb: "climb on")
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

    /// Processes the climb on action.
    ///
    /// - Parameter context: The `ActionContext` containing the command and game state.
    /// - Returns: An `ActionResult` with the action outcome.
    public func process(context: ActionContext) async throws -> ActionResult {
        guard case .item(let targetItemID) = context.command.directObject else {
            let message = context.message.actionHandlerInternalError(
                handler: "ClimbOnActionHandler",
                details: "directObject was not an item in process"
            )
            throw ActionResponse.internalEngineError(message)
        }

        let targetItem = try await context.engine.item(targetItemID)

        // Default behavior: You can't climb on most things
        return ActionResult(
            context.message.climbOnFailure(item: targetItem.withDefiniteArticle),
            await context.engine.setFlag(.isTouched, on: targetItem),
            await context.engine.updatePronouns(to: targetItem)
        )
    }
}
