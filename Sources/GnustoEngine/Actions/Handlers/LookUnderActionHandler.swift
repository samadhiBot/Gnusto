import Foundation

/// Handles the LOOK UNDER verb.
///
/// The ZIL equivalent is the `V-LOOK-UNDER` routine. This action represents the player
/// attempting to look underneath an object.
public struct LookUnderActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .under, .directObject),
        .match(.verb, .beneath, .directObject),
        .match(.verb, .below, .directObject),
    ]

    public let verbs: [VerbID] = [.look, .peek]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    /// Validates that the action can be performed.
    ///
    /// - Parameter context: The `ActionContext` containing the command and game state.
    /// - Returns: An `ActionResult` indicating validation success or failure.
        public func process(
        command: Command,
        engine: GameEngine
    ) async throws -> ActionResult {

        guard let directObjectRef = command.directObject else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.doWhat(action: "look under")
            )
        }

        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.cannotDoThat(verb: "look under")
            )
        }

        // Check if item exists and is reachable
        guard (try? await engine.item(targetItemID)) != nil else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.cannotDoThat(verb: "look under")
            )
        }

        guard await engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }
    /// Processes the look under action.
    ///
    /// - Parameter context: The `ActionContext` containing the command and game state.
    /// - Returns: An `ActionResult` with the action outcome.
        guard case .item(let targetItemID) = command.directObject else {
            throw ActionResponse.internalEngineError(
                "LookUnder: directObject was not an item in process."
            )
        }

        let targetItem = try await engine.item(targetItemID)

        // Default behavior: You can't see anything of interest under most things
        return ActionResult(
            engine.messenger.nothingOfInterestUnder(item: targetItem.withDefiniteArticle),
            await engine.setFlag(.isTouched, on: targetItem),
            await engine.updatePronouns(to: targetItem)
        )
    }
}
