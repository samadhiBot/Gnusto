import Foundation

/// Handles the "BLOW" command for blowing on objects like candles, fires, wind instruments, etc.
/// Implements blowing mechanics following ZIL patterns.
public struct BlowActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject),
        .match(.verb, .on, .directObject),
    ]

    public let verbs: [Verb] = [.blow, .puff]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "BLOW" command.
    ///
    /// Handles blowing on objects or general blowing. Special items like candles,
    /// fires, or wind instruments can have custom behavior via ItemEventHandlers.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        guard let targetItemID = command.directObjectItemID else {
            return ActionResult(
                engine.messenger.blow()
            )
        }

        guard await engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }

        let targetItem = try await engine.item(targetItemID)

        return ActionResult(
            engine.messenger.blowOn(
                item: targetItem.withDefiniteArticle
            ),
            await engine.setFlag(.isTouched, on: targetItem),
            await engine.updatePronouns(to: targetItem),
        )
    }
}
