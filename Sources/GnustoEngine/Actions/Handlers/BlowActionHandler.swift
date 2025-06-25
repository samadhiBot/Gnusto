import Foundation

/// Handles the "BLOW" command for blowing on objects like candles, fires, wind instruments, etc.
/// Implements blowing mechanics following ZIL patterns.
public struct BlowActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject),
        .match(.verb, .on, .directObject),
    ]

    public let verbs: [VerbID] = [.blow, .puff]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "BLOW" command.
    ///
    /// Handles blowing on objects or general blowing. Special items like candles,
    /// fires, or wind instruments can have custom behavior via ItemEventHandlers.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        // Blow can be used without an object (general blowing) or with an object
        guard
            let directObjectRef = command.directObject,
            case .item(let targetItemID) = directObjectRef
        else {
            return ActionResult(
                engine.messenger.blowGeneral()
            )
        }

        let targetItem = try await engine.item(targetItemID)

        // Default behavior for blowing on objects
        let message =
            if targetItem.hasFlag(.isLightSource) && targetItem.hasFlag(.isLit) {
                // Blowing on lit light sources might extinguish them
                engine.messenger.blowOnLightSource(
                    item: targetItem.withDefiniteArticle
                )
            } else if targetItem.hasFlag(.isFlammable) {
                // Specific extinguishing behavior should use TurnOffActionHandler or custom logic
                engine.messenger.blowOnFlammable(
                    item: targetItem.withDefiniteArticle
                )
            } else {
                engine.messenger.blowOnGeneric(
                    item: targetItem.withDefiniteArticle
                )
            }

        return ActionResult(
            message,
            await engine.setFlag(.isTouched, on: targetItem),
            await engine.updatePronouns(to: targetItem),
        )
    }
}
