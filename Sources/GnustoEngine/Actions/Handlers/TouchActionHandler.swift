import Foundation

/// Handles the "TOUCH" command and its synonyms (e.g., "FEEL", "PAT"), allowing the
/// player to physically interact with an item by touching it.
public struct TouchActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject)
    ]

    public let verbs: [VerbID] = [.touch, .feel]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "TOUCH" command.
    ///
    /// This action validates prerequisites and provides tactile feedback for touching items.
    /// Sets the .isTouched flag on the target item and provides appropriate messaging.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        // Ensure we have a direct object and it's an item
        guard let directObjectRef = command.directObject else {
            throw ActionResponse.custom(
                engine.messenger.doWhat(verb: command.verb)
            )
        }
        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.thatsNotSomethingYouCan(.touch)
            )
        }

        // Check if item exists and is accessible
        let targetItem = try await engine.item(targetItemID)
        guard await engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }

        return ActionResult(
            engine.messenger.nothingSpecial(verb: .feel),
            await engine.setFlag(.isTouched, on: targetItem),
            await engine.updatePronouns(to: targetItem)
        )
    }
}
