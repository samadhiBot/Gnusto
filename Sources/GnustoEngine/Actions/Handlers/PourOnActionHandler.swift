import Foundation

/// Handles the "POUR ON" command for pouring liquids on objects.
/// Implements pouring mechanics following ZIL patterns for liquid manipulation.
public struct PourOnActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let verbID: VerbID = .pourOn

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject, .on, .indirectObject),
        .match(.verb, .directObject, .indirectObject),
    ]

    public let synonyms: [String] = ["spill on"]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Validates the "POUR ON" command.
    ///
    /// This method ensures that:
    /// 1. A direct object is specified (what to pour).
    /// 2. An indirect object is specified (what to pour on).
    /// 3. The target items exist and are reachable.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: Various `ActionResponse` errors if validation fails.
    public func validate(context: ActionContext) async throws {
        // Pour requires a direct object (what to pour)
        guard let directObjectRef = context.command.directObject else {
            throw ActionResponse.prerequisiteNotMet(
                context.message.doWhat(verb: .pourOn)
            )
        }
        guard case .item(let sourceItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet(context.message.pourCannotPourThat())
        }

        let sourceItem = try await context.engine.item(sourceItemID)

        // Pour requires an indirect object (what to pour on)
        guard let indirectObjectRef = context.command.indirectObject else {
            throw ActionResponse.prerequisiteNotMet(
                context.message.pourItemOnWhat(item: sourceItem.withDefiniteArticle)
            )
        }
        guard case .item(let targetItemID) = indirectObjectRef else {
            throw ActionResponse.prerequisiteNotMet(
                context.message.pourCannotPourItemOnThat(item: sourceItem.withDefiniteArticle)
            )
        }

        // Check if source exists and is reachable
        _ = try await context.engine.item(sourceItemID)
        guard await context.engine.playerCanReach(sourceItemID) else {
            throw ActionResponse.itemNotAccessible(sourceItemID)
        }

        // Check if target exists and is reachable
        _ = try await context.engine.item(targetItemID)
        guard await context.engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }
    }

    /// Processes the "POUR ON" command.
    ///
    /// Handles pouring attempts with different types of liquids and targets.
    /// Provides appropriate responses following ZIL traditions.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` with appropriate pouring message and state changes.
    public func process(context: ActionContext) async throws -> ActionResult {
        guard let directObjectRef = context.command.directObject,
            case .item(let sourceItemID) = directObjectRef,
            let indirectObjectRef = context.command.indirectObject,
            case .item(let targetItemID) = indirectObjectRef
        else {
            throw ActionResponse.internalEngineError(
                "PourOnActionHandler: missing required objects in process."
            )
        }

        let sourceItem = try await context.engine.item(sourceItemID)
        let targetItem = try await context.engine.item(targetItemID)

        if sourceItem.id == targetItem.id {
            throw ActionResponse.prerequisiteNotMet(
                context.message.pourCannotPourItself(
                    item: sourceItem.withDefiniteArticle
                )
            )
        }

        return ActionResult(
            context.message.pourItemOn(
                item: sourceItem.withDefiniteArticle,
                target: targetItem.withDefiniteArticle
            ),
            await context.engine.setFlag(.isTouched, on: sourceItem),
            await context.engine.setFlag(.isTouched, on: targetItem),
            await context.engine.updatePronouns(to: sourceItem, targetItem),
        )
    }
}
