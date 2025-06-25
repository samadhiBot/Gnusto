import Foundation

/// Handles the "JUMP" command and its synonyms (e.g., "LEAP", "HOP").
/// Implements jumping behavior following ZIL patterns.
public struct JumpActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb),
        .match(.verb, .directObject),
        .match(.verb, .over, .directObject),
    ]

    public let verbs: [VerbID] = [.jump, .leap, .hop]

    public let requiresLight: Bool = false

    // MARK: - Action Processing Methods

    public init() {}

    /// Validates the "JUMP" command.
    ///
    /// This method ensures that if a direct object is specified,
    /// it exists and is reachable.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: Various `ActionResponse` errors if validation fails.
        public func process(
        command: Command,
        engine: GameEngine
    ) async throws -> ActionResult {

        // JUMP with no object is always valid (general jumping)
        guard let directObjectRef = command.directObject else {
            return
        }

        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.cannotDoThat(verb: "jump")
            )
        }

        // Check if target exists and is reachable
        _ = try await engine.item(targetItemID)
        guard await engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }
    /// Processes the "JUMP" command.
    ///
    /// Handles jumping in place or jumping over objects.
    /// Provides appropriate responses based on ZIL traditions.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` with appropriate jump message and state changes.
        // Handle JUMP with no object - general jumping
        guard let directObjectRef = command.directObject else {
            // General jumping - use random response from MessageProvider
            return ActionResult(
                engine.messenger.jumpResponse()
            )
        }

        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.internalEngineError(
                "JumpActionHandler: directObject was not an item in process.")
        }

        let targetItem = try await engine.item(targetItemID)

        // Determine appropriate response based on object type
        let message =
            if targetItem.hasFlag(.isCharacter) {
                // Can't jump characters
                engine.messenger.jumpCharacter(character: targetItem.withDefiniteArticle)
            } else {
                // Generic jumping response for objects
                engine.messenger.jumpLargeObject(item: targetItem.withDefiniteArticle)
            }

        return ActionResult(
            message,
            await engine.setFlag(.isTouched, on: targetItem),
            await engine.updatePronouns(to: targetItem)
        )
    }
}
