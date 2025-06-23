import Foundation

/// Handles the "SHAKE" command for shaking objects.
/// Implements shaking mechanics following ZIL patterns for physical interactions.
public struct ShakeActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let verbID: VerbID = .shake

    public let syntax: [SyntaxRule] = [
        SyntaxRule(.verb, .directObject)
    ]

    public let synonyms: [String] = ["rattle"]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods
    public init() {}

    /// Validates the "SHAKE" command.
    ///
    /// This method ensures that:
    /// 1. A direct object is specified (what to shake).
    /// 2. The target item exists and is reachable.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: Various `ActionResponse` errors if validation fails.
    public func validate(context: ActionContext) async throws {
        // Shake requires a direct object (what to shake)
        guard let directObjectRef = context.command.directObject else {
            throw ActionResponse.prerequisiteNotMet(
                context.message.doWhat(verb: .shake)
            )
        }
        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet(
                context.message.cannotDoThat(verb: "shake")
            )
        }

        // Check if target exists and is reachable
        _ = try await context.engine.item(targetItemID)
        guard await context.engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }
    }

    /// Processes the "SHAKE" command.
    ///
    /// Handles shaking attempts on different types of objects.
    /// Generally provides descriptive responses following ZIL traditions.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` with appropriate shaking message and state changes.
    public func process(context: ActionContext) async throws -> ActionResult {
        guard let directObjectRef = context.command.directObject,
            case .item(let targetItemID) = directObjectRef
        else {
            throw ActionResponse.internalEngineError(
                "ShakeActionHandler: directObject was not an item in process.")
        }

        let targetItem = try await context.engine.item(targetItemID)

        // Determine appropriate response based on object type and properties
        let message =
            if targetItem.hasFlag(.isCharacter) {
                // Shaking characters might not be appropriate
                context.message.shakeCharacter(character: targetItem.withDefiniteArticle)
            } else if targetItem.hasFlag(.isLiquidContainer) {
                // Special message for liquid containers
                context.message.shakeLiquidContainer(item: targetItem.withDefiniteArticle)
            } else if targetItem.hasFlag(.isContainer) {
                // Shaking containers might reveal contents
                if targetItem.hasFlag(.isOpen) {
                    context.message.shakeOpenContainer(
                        container: targetItem.withDefiniteArticle
                    )
                } else {
                    context.message.shakeClosedContainer(
                        container: targetItem.withDefiniteArticle
                    )
                }
            } else if targetItem.hasFlag(.isTakable) {
                // Message for a generic takable object
                context.message.shakeTakableObject(item: targetItem.withDefiniteArticle)
            } else {
                // Generic shaking response for objects
                context.message.shakeFixedObject(item: targetItem.withDefiniteArticle)
            }

        return ActionResult(
            message: message,
            changes: [
                await context.engine.setFlag(.isTouched, on: targetItem),
                await context.engine.updatePronouns(to: targetItem),
            ]
        )
    }

    /// Performs any post-processing after the shake action completes.
    ///
    /// Currently no post-processing is needed for basic shaking.
    ///
    /// - Parameter context: The action context for the current action.
    public func postProcess(context: ActionContext) async throws {
        // No post-processing needed for shake
    }
}
