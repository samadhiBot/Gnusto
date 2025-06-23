import Foundation

/// Handles the LOOK UNDER verb.
///
/// The ZIL equivalent is the `V-LOOK-UNDER` routine. This action represents the player
/// attempting to look underneath an object.
public struct LookUnderActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let verbID: VerbID = .lookUnder

    public let syntax: [SyntaxRule] = [
        .match(.verb, .under, .directObject),
        .match(.verb, .beneath, .directObject),
    ]

    public let synonyms: [String] = ["look", "peek"]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    /// Validates that the action can be performed.
    ///
    /// - Parameter context: The `ActionContext` containing the command and game state.
    /// - Returns: An `ActionResult` indicating validation success or failure.
    public func validate(context: ActionContext) async throws {
        guard let directObjectRef = context.command.directObject else {
            throw ActionResponse.prerequisiteNotMet(
                context.message.doWhat(action: "look under")
            )
        }

        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet(
                context.message.cannotDoThat(verb: "look under")
            )
        }

        // Check if item exists and is reachable
        guard (try? await context.engine.item(targetItemID)) != nil else {
            throw ActionResponse.prerequisiteNotMet(
                context.message.cannotDoThat(verb: "look under")
            )
        }

        guard await context.engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }
    }

    /// Processes the look under action.
    ///
    /// - Parameter context: The `ActionContext` containing the command and game state.
    /// - Returns: An `ActionResult` with the action outcome.
    public func process(context: ActionContext) async throws -> ActionResult {
        guard case .item(let targetItemID) = context.command.directObject else {
            throw ActionResponse.internalEngineError(
                "LookUnder: directObject was not an item in process."
            )
        }

        let targetItem = try await context.engine.item(targetItemID)

        // Default behavior: You can't see anything of interest under most things
        return ActionResult(
            context.message.nothingOfInterestUnder(item: targetItem.withDefiniteArticle),
            await context.engine.setFlag(.isTouched, on: targetItem),
            await context.engine.updatePronouns(to: targetItem)
        )
    }
}
