import Foundation

/// Handles the "JUMP" command and its synonyms (e.g., "LEAP", "HOP").
/// Implements jumping behavior following ZIL patterns.
public struct JumpActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let verbID: VerbID = .jump

    public let syntax: [SyntaxRule] = [
        .match(.verb),
        .match(.verb, .directObject),
    ]

    public let synonyms: [String] = ["leap", "hop"]

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
    public func validate(context: ActionContext) async throws {
        // JUMP with no object is always valid (general jumping)
        guard let directObjectRef = context.command.directObject else {
            return
        }

        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet(
                context.message.cannotDoThat(verb: "jump")
            )
        }

        // Check if target exists and is reachable
        _ = try await context.engine.item(targetItemID)
        guard await context.engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }
    }

    /// Processes the "JUMP" command.
    ///
    /// Handles jumping in place or jumping over objects.
    /// Provides appropriate responses based on ZIL traditions.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` with appropriate jump message and state changes.
    public func process(context: ActionContext) async throws -> ActionResult {
        // Handle JUMP with no object - general jumping
        guard let directObjectRef = context.command.directObject else {
            // General jumping - use random response from MessageProvider
            return ActionResult(
                context.message.jumpResponse()
            )
        }

        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.internalEngineError(
                "JumpActionHandler: directObject was not an item in process.")
        }

        let targetItem = try await context.engine.item(targetItemID)

        // Determine appropriate response based on object type
        let message =
            if targetItem.hasFlag(.isCharacter) {
                // Can't jump characters
                context.message.jumpCharacter(character: targetItem.withDefiniteArticle)
            } else {
                // Generic jumping response for objects
                context.message.jumpLargeObject(item: targetItem.withDefiniteArticle)
            }

        return ActionResult(
            message: message,
            changes: [
                await context.engine.setFlag(.isTouched, on: targetItem),
                await context.engine.updatePronouns(to: targetItem),
            ]
        )
    }

    /// Performs any post-processing after the jump action completes.
    ///
    /// Currently no post-processing is needed for basic jumping.
    ///
    /// - Parameter context: The action context for the current action.
    public func postProcess(context: ActionContext) async throws {
        // No post-processing needed for jump
    }
}
