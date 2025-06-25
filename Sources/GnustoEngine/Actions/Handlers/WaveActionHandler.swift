import Foundation

/// Handles the "WAVE" command for waving objects.
/// Implements waving mechanics following ZIL patterns for physical interactions.
public struct WaveActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject),
        .match(.wave, .at, .directObject),
        .match(.wave, .to, .directObject),
        .match(.verb, .directObject, .at, .indirectObject),
    ]

    public let verbs: [VerbID] = [.wave, .brandish]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods
    public init() {}

    /// Validates the "WAVE" command.
    ///
    /// This method ensures that:
    /// 1. A direct object is specified (what to wave).
    /// 2. The target item exists and is reachable.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: Various `ActionResponse` errors if validation fails.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {

        // Wave requires a direct object (what to wave)
        guard let directObjectRef = command.directObject else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.doWhat(verb: command.verb)
            )
        }
        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.cannotDoThat(verb: "wave")
            )
        }

        // Check if target exists and is reachable
        _ = try await engine.item(targetItemID)
        guard await engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }
    /// Processes the "WAVE" command.
    ///
    /// Handles waving attempts on different types of objects.
    /// Generally provides descriptive responses following ZIL traditions.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` with appropriate waving message and state changes.
        guard let directObjectRef = command.directObject,
            case .item(let targetItemID) = directObjectRef
        else {
            throw ActionResponse.internalEngineError(
                "WaveActionHandler: directObject was not an item in process.")
        }

        let targetItem = try await engine.item(targetItemID)

        // Determine appropriate response based on object type and properties
        let message = if !targetItem.hasFlag(.isTakable) {
            // Fixed objects can't be waved
            engine.messenger.waveFixedObject(item: targetItem.withDefiniteArticle)
        } else if targetItem.hasFlag(.isWeapon) {
            // Weapons are brandished
            engine.messenger.waveWeapon(item: targetItem.withDefiniteArticle)
        } else {
            // Generic waving response for other takable objects
            engine.messenger.waveObject(item: targetItem.withDefiniteArticle)
        }

        return ActionResult(
            message,
            await engine.setFlag(.isTouched, on: targetItem),
            await engine.updatePronouns(to: targetItem)
        )
    }
}
