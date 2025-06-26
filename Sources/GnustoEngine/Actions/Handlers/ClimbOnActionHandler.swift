import Foundation

/// Handles the CLIMB ON verb (synonyms: SIT ON, STAND ON).
///
/// The ZIL equivalent is the `V-CLIMB-ON` routine. This action represents the player
/// attempting to climb onto or sit on an object.
public struct ClimbOnActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.climb, .on, .directObject),
        .match(.get, .on, .directObject),
        .match(.sit, .on, .directObject),
        .match(.mount, .directObject),
    ]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    /// Processes the climb on action.
    ///
    /// - Parameter command: The command being processed.
    /// - Parameter engine: The game engine.
    /// - Returns: An `ActionResult` with the action outcome.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        guard let directObjectRef = command.directObject else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.doWhat(action: "climb on")
            )
        }

        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.cannotDoThat(verb: "climb on")
            )
        }

        // Check if item exists and is reachable
        guard (try? await engine.item(targetItemID)) != nil else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }

        guard await engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }

        let targetItem = try await engine.item(targetItemID)

        // Default behavior: You can't climb on most things
        return ActionResult(
            engine.messenger.climbOnFailure(item: targetItem.withDefiniteArticle),
            await engine.setFlag(.isTouched, on: targetItem),
            await engine.updatePronouns(to: targetItem)
        )
    }
}
