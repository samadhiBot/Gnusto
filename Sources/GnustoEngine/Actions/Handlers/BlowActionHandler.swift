import Foundation

/// Handles the "BLOW" command for blowing on objects like candles, fires, wind instruments, etc.
/// Implements blowing mechanics following ZIL patterns.
public struct BlowActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let verbID: VerbID = .blow

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject),
        .match(.verb, .on, .directObject),
    ]

    public let synonyms: [String] = ["puff"]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Validates the "BLOW" command.
    ///
    /// This method ensures that:
    /// 1. If a direct object is specified, it exists and is reachable.
    /// 2. The command is properly formed (can be "blow" alone or "blow object").
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: Various `ActionResponse` errors if validation fails.
    public func validate(context: ActionContext) async throws {
        // Blow can be used without an object (general blowing) or with an object
        if let directObjectRef = context.command.directObject {
            guard case .item(let targetItemID) = directObjectRef else {
                throw ActionResponse.prerequisiteNotMet(
                    context.message.thatsNotSomethingYouCan(.blow)
                )
            }

            // Check if target exists and is reachable
            _ = try await context.engine.item(targetItemID)
            guard await context.engine.playerCanReach(targetItemID) else {
                throw ActionResponse.itemNotAccessible(targetItemID)
            }
        }
    }

    /// Processes the "BLOW" command.
    ///
    /// Handles blowing on objects or general blowing. Special items like candles,
    /// fires, or wind instruments can have custom behavior via ItemEventHandlers.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` with appropriate blow message and state changes.
    public func process(context: ActionContext) async throws -> ActionResult {
        // Handle blowing on a specific object
        guard
            let directObjectRef = context.command.directObject,
            case .item(let targetItemID) = directObjectRef
        else {
            // General blowing without a target
            return ActionResult(
                context.message.blowGeneral()
            )
        }

        let targetItem = try await context.engine.item(targetItemID)

        // Default behavior for blowing on objects
        let message =
            if targetItem.hasFlag(.isLightSource) && targetItem.hasFlag(.isLit) {
                // Blowing on lit light sources might extinguish them
                context.message.blowOnLightSource(
                    item: targetItem.withDefiniteArticle
                )
            } else if targetItem.hasFlag(.isFlammable) {
                // Specific extinguishing behavior should use TurnOffActionHandler or custom logic
                context.message.blowOnFlammable(
                    item: targetItem.withDefiniteArticle
                )
            } else {
                context.message.blowOnGeneric(
                    item: targetItem.withDefiniteArticle
                )
            }

        return ActionResult(
            message,
            await context.engine.setFlag(.isTouched, on: targetItem),
            await context.engine.updatePronouns(to: targetItem),
        )
    }
}
