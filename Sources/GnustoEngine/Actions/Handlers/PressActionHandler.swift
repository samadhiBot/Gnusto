import Foundation

/// Handles the "PRESS" command for pressing buttons, switches, and other pressable objects.
/// Implements pressing mechanics following ZIL patterns.
public struct PressActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject)
    ]

    public let verbs: [VerbID] = [.press, .depress, .push]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "PRESS" command.
    ///
    /// This action validates prerequisites and handles pressing objects. Items with the
    /// `.isPressable` flag can be pressed and may have special behavior defined via
    /// ItemEventHandlers. Most objects cannot be pressed effectively.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        // Press requires a direct object (what to press)
        guard let directObjectRef = command.directObject else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.doWhat(verb: command.verb)
            )
        }
        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.thatsNotSomethingYouCan(.press)
            )
        }

        // Check if target exists and is reachable
        let targetItem = try await engine.item(targetItemID)
        guard await engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }

        // Check if item is pressable
        let message =
            if targetItem.hasFlag(.isPressable) {
                engine.messenger.pressSuccess(item: targetItem.withDefiniteArticle)
                // Note: Specific press behavior should be handled by ItemEventHandlers
            } else {
                // Default behavior: most things can't be pressed effectively
                engine.messenger.cannotDoThat(
                    verb: .press,
                    item: targetItem.withDefiniteArticle
                )
            }

        return ActionResult(
            message,
            await engine.setFlag(.isTouched, on: targetItem),
            await engine.updatePronouns(to: targetItem)
        )
    }
}
