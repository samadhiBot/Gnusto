import Foundation

/// Handles the "INFLATE" command for inflating objects like balloons, rafts, life preservers, etc.
/// Implements inflation mechanics following ZIL patterns.
public struct InflateActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject),
        .match(.verb, .directObject, .with, .indirectObject),
        .match(.verb(.blow), .up, .directObject),
        .match(.verb(.blow), .up, .directObject, .with, .indirectObject),
    ]

    public let synonyms: [VerbID] = [.inflate]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Validates the "INFLATE" command.
    ///
    /// This method ensures that:
    /// 1. A direct object is specified (what to inflate).
    /// 2. The target item exists and is reachable.
    /// 3. The item has the `.isInflatable` flag or can be inflated.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: Various `ActionResponse` errors if validation fails.
    public func validate(context: ActionContext) async throws {
        // Inflate requires a direct object (what to inflate)
        guard let directObjectRef = context.command.directObject else {
            throw ActionResponse.prerequisiteNotMet(
                context.message.doWhat(verb: context.command.verb)
            )
        }
        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet(
                context.message.thatsNotSomethingYouCan(.inflate)
            )
        }

        // Check if target exists and is reachable
        let targetItem = try await context.engine.item(targetItemID)
        guard await context.engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }

        // Check if item is inflatable
        guard targetItem.hasFlag(.isInflatable) else {
            throw ActionResponse.prerequisiteNotMet(
                context.message.cannotInflate(item: targetItem.withDefiniteArticle)
            )
        }
    }

    /// Processes the "INFLATE" command.
    ///
    /// Handles inflating objects. If the object is already inflated, provides
    /// an appropriate message. If it can be inflated, sets the `.isInflated` flag
    /// and provides confirmation.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` with appropriate inflate message and state changes.
    public func process(context: ActionContext) async throws -> ActionResult {
        guard let directObjectRef = context.command.directObject,
            case .item(let targetItemID) = directObjectRef
        else {
            let message = context.message.actionHandlerInternalError(
                handler: "InflateActionHandler",
                details: "directObject was not an item in process"
            )
            throw ActionResponse.internalEngineError(message)
        }

        let targetItem = try await context.engine.item(targetItemID)

        // Check if already inflated
        let isAlreadyInflated = try await context.engine.hasFlag(.isInflated, on: targetItemID)

        let message =
            if isAlreadyInflated {
                context.message.itemAlreadyInflated(item: targetItem.withDefiniteArticle)
            } else {
                context.message.inflateSuccess(item: targetItem.withDefiniteArticle)
            }

        return ActionResult(
            message: message,
            changes: [
                await context.engine.setFlag(.isTouched, on: targetItem),
                await context.engine.updatePronouns(to: targetItem),
                isAlreadyInflated
                    ? nil : await context.engine.setFlag(.isInflated, on: targetItem),
            ]
        )
    }
}
