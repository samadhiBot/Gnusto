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

    public let verbs: [Verb] = [.look, .peek]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "LOOK UNDER" command.
    ///
    /// This action validates prerequisites and handles looking underneath objects.
    /// Checks that the item exists and is accessible, then provides appropriate messaging.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
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

        // Check if item exists and is accessible
        let targetItem = try await engine.item(targetItemID)
        guard await engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }

        // Determine appropriate message based on object type
//        let message =
//            if targetItem.hasFlag(.isCharacter) {
//                // Looking under characters - not appropriate
//                engine.messenger.cannotLookUnderCharacter(
//                    character: targetItem.withDefiniteArticle
//                )
//            } else if targetItem.hasFlag(.isSurface) || targetItem.hasFlag(.isContainer) {
//                // Some items might have things hidden underneath
//                engine.messenger.nothingOfInterestUnder(
//                    item: targetItem.withDefiniteArticle
//                )
//            } else {
//                // Default behavior for most objects
//                engine.messenger.nothingOfInterestUnder(
//                    item: targetItem.withDefiniteArticle
//                )
//            }
        let message = "🤡 `look under` placeholder for \(targetItem)"

        return ActionResult(
            message,
            await engine.setFlag(.isTouched, on: targetItem),
            await engine.updatePronouns(to: targetItem)
        )
    }
}
