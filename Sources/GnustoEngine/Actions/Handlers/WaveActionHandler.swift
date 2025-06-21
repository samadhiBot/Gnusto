import Foundation

/// Handles the "WAVE" command for waving objects.
/// Implements waving mechanics following ZIL patterns for physical interactions.
public struct WaveActionHandler: ActionHandler {
    public init() {}

    /// Validates the "WAVE" command.
    ///
    /// This method ensures that:
    /// 1. A direct object is specified (what to wave).
    /// 2. The target item exists and is reachable.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: Various `ActionResponse` errors if validation fails.
    public func validate(context: ActionContext) async throws {
        // Wave requires a direct object (what to wave)
        guard let directObjectRef = context.command.directObject else {
            throw ActionResponse.prerequisiteNotMet(
                context.message.doWhat(verb: .wave)
            )
        }
        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet(
                context.message.cannotActOnThat(verb: "wave")
            )
        }

        // Check if target exists and is reachable
        _ = try await context.engine.item(targetItemID)
        guard await context.engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }
    }

    /// Processes the "WAVE" command.
    ///
    /// Handles waving attempts on different types of objects.
    /// Generally provides descriptive responses following ZIL traditions.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` with appropriate waving message and state changes.
    public func process(context: ActionContext) async throws -> ActionResult {
        guard let directObjectRef = context.command.directObject,
            case .item(let targetItemID) = directObjectRef
        else {
            throw ActionResponse.internalEngineError(
                "WaveActionHandler: directObject was not an item in process.")
        }

        let targetItem = try await context.engine.item(targetItemID)

        // Determine appropriate response based on object type and properties
        let message =
            if targetItem.hasFlag(.isCharacter) {
                // Waving at characters
                context.message.waveCharacter(character: targetItem.withDefiniteArticle)
            } else if !targetItem.hasFlag(.isTakable) {
                // Fixed objects can't be waved
                context.message.waveFixedObject(item: targetItem.withDefiniteArticle)
            } else if targetItem.hasFlag(.isWand) || targetItem.hasFlag(.isStaff) {
                // Magical items
                context.message.waveMagicalItem(item: targetItem.withDefiniteArticle)
            } else if targetItem.hasFlag(.isWeapon) {
                // Weapons are brandished
                context.message.waveWeapon(item: targetItem.withDefiniteArticle)
            } else if targetItem.hasFlag(.isFlag) {
                // Flags have their own message
                context.message.waveFlag(item: targetItem.withDefiniteArticle)
            } else {
                // Generic waving response for other takable objects
                context.message.waveFixedObject(item: targetItem.withDefiniteArticle)
            }

        return ActionResult(
            message: message,
            changes: [
                await context.engine.setFlag(.isTouched, on: targetItem),
                await context.engine.updatePronouns(to: targetItem),
            ]
        )
    }

    /// Performs any post-processing after the wave action completes.
    ///
    /// Currently no post-processing is needed for basic waving.
    ///
    /// - Parameter context: The action context for the current action.
    public func postProcess(context: ActionContext) async throws {
        // No post-processing needed for wave
    }
}
