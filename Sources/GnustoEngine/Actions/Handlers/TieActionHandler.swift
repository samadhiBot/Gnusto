import Foundation

/// Handles the "TIE" command for tying objects together.
/// Implements tying mechanics following ZIL patterns for object binding and connection.
public struct TieActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject),
        .match(.verb, .directObject, .to, .indirectObject),
        .match(.verb, .directObject, .with, .indirectObject),
    ]

    public let verbs: [VerbID] = [.tie, .fasten, .bind]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "TIE" command.
    ///
    /// Handles tying attempts on different types of objects.
    /// Can tie objects together or just tie objects in general.
    ///
    /// - Parameter command: The command being processed.
    /// - Parameter engine: The game engine.
    /// - Returns: An `ActionResult` with appropriate tying message and state changes.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        // Tie requires a direct object (what to tie)
        guard let directObjectRef = command.directObject else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.doWhat(verb: command.verb)
            )
        }

        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.tieCannotTieThat()
            )
        }

        // Check if target exists and is reachable
        let targetItem = try await engine.item(targetItemID)

        guard await engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }

        // If there's an indirect object, validate it too
        if let indirectObjectRef = command.indirectObject {
            guard case .item(let indirectItemID) = indirectObjectRef else {
                throw ActionResponse.prerequisiteNotMet(
                    engine.messenger.tieCannotTieToThat()
                )
            }

            let indirectItem = try await engine.item(indirectItemID)

            guard await engine.playerCanReach(indirectItemID) else {
                throw ActionResponse.itemNotAccessible(indirectItemID)
            }

            // Tie X to Y
            let message = await handleTyingTogether(
                targetItem: targetItem,
                indirectItem: indirectItem,
                engine: engine
            )

            return ActionResult(
                message,
                await engine.setFlag(.isTouched, on: targetItem),
                await engine.updatePronouns(to: targetItem),
                await engine.setFlag(.isTouched, on: indirectItem)
            )
        } else {
            // Just "TIE X" - tie the object by itself
            let message = await handleTyingAlone(
                targetItem: targetItem,
                engine: engine
            )

            return ActionResult(
                message,
                await engine.setFlag(.isTouched, on: targetItem),
                await engine.updatePronouns(to: targetItem)
            )
        }
    }

    // MARK: - Private Helper Methods

    /// Handles tying two objects together.
    private func handleTyingTogether(
        targetItem: Item,
        indirectItem: Item,
        engine: GameEngine
    ) async -> String {
        // Check if we're trying to tie something to itself
        if targetItem.id == indirectItem.id {
            return engine.messenger.tieCannotTieToSelf(item: targetItem.name)
        }

        // General tying attempts
        if targetItem.hasFlag(.isCharacter) || indirectItem.hasFlag(.isCharacter) {
            return engine.messenger.tieCannotTieLivingBeings()
        }

        return engine.messenger.tieNeedsSomethingToTieWith(item: targetItem.name)
    }

    /// Handles tying a single object.
    private func handleTyingAlone(
        targetItem: Item,
        engine: GameEngine
    ) async -> String {
        if targetItem.hasFlag(.isCharacter) {
            return engine.messenger.tieNeedsSomethingToTieCharacterWith(
                character: targetItem.name
            )
        } else if targetItem.hasFlag(.isRope) {
            // Special case: tying a rope-like object creates a knot
            return engine.messenger.tieKnotInRope(item: targetItem.withDefiniteArticle)
        } else {
            return engine.messenger.tieNeedsSomethingToTieWith(
                item: targetItem.name
            )
        }
    }
}
