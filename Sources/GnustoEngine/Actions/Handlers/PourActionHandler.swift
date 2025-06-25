import Foundation

/// Handles the "POUR ON" command for pouring liquids on objects.
/// Implements pouring mechanics following ZIL patterns for liquid manipulation.
public struct PourActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb),
        .match(.verb, .directObject),
        .match(.verb, .directObject, .on, .indirectObject),
    ]

    public let verbs: [VerbID] = [.pour, .spill]

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
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {

        // Pour requires a direct object (what to pour)
        guard let directObjectRef = command.directObject else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.doWhat(action: "pour")
            )
        }
        guard case .item(let sourceItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet(engine.messenger.pourCannotPourThat())
        }

        let sourceItem = try await engine.item(sourceItemID)

        // Pour requires an indirect object (what to pour on)
        guard let indirectObjectRef = command.indirectObject else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.pourItemOnWhat(item: sourceItem.withDefiniteArticle)
            )
        }
        guard case .item(let targetItemID) = indirectObjectRef else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.pourCannotPourItemOnThat(item: sourceItem.withDefiniteArticle)
            )
        }

        // Check if source exists and is reachable
        _ = try await engine.item(sourceItemID)
        guard await engine.playerCanReach(sourceItemID) else {
            throw ActionResponse.itemNotAccessible(sourceItemID)
        }

        // Check if target exists and is reachable
        _ = try await engine.item(targetItemID)
        guard await engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }
    /// Processes the "POUR ON" command.
    ///
    /// Handles pouring attempts with different types of liquids and targets.
    /// Provides appropriate responses following ZIL traditions.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` with appropriate pouring message and state changes.
        guard let directObjectRef = command.directObject,
            case .item(let sourceItemID) = directObjectRef,
            let indirectObjectRef = command.indirectObject,
            case .item(let targetItemID) = indirectObjectRef
        else {
            throw ActionResponse.internalEngineError(
                "PourActionHandler: missing required objects in process."
            )
        }

        let sourceItem = try await engine.item(sourceItemID)
        let targetItem = try await engine.item(targetItemID)

        if sourceItem.id == targetItem.id {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.pourCannotPourItself(
                    item: sourceItem.withDefiniteArticle
                )
            )
        }

        return ActionResult(
            engine.messenger.pourItemOn(
                item: sourceItem.withDefiniteArticle,
                target: targetItem.withDefiniteArticle
            ),
            await engine.setFlag(.isTouched, on: sourceItem),
            await engine.setFlag(.isTouched, on: targetItem),
            await engine.updatePronouns(to: sourceItem, targetItem),
        )
    }
}
