import Foundation

/// Handles the "THROW" command for throwing objects with optional targets.
/// Implements object throwing mechanics following ZIL patterns.
public struct ThrowActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject),
        .match(.verb, .directObject, .at, .indirectObject),
        .match(.verb, .directObject, .to, .indirectObject),
    ]

    public let verbs: [VerbID] = [.throw, .hurl, .toss, .chuck]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Validates the "THROW" command.
    ///
    /// This method ensures that:
    /// 1. A direct object is specified (what to throw).
    /// 2. The player is holding the item to throw.
    /// 3. If a target is specified, it exists and is reachable.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: Various `ActionResponse` errors if validation fails.
        public func process(
        command: Command,
        engine: GameEngine
    ) async throws -> ActionResult {

        // Throw requires a direct object (what to throw)
        guard let directObjectRef = command.directObject else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.doWhat(verb: command.verb)
            )
        }
        guard case .item(let itemToThrowID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.cannotDoThat(verb: "throw")
            )
        }

        // Check if item exists and is held
        let itemToThrow = try await engine.item(itemToThrowID)
        guard itemToThrow.parent == .player else {
            throw ActionResponse.itemNotHeld(itemToThrowID)
        }

        // If a target is specified, validate it
        if let indirectObjectRef = command.indirectObject {
            guard case .item(let targetItemID) = indirectObjectRef else {
                throw ActionResponse.prerequisiteNotMet(
                    engine.messenger.cannotActWithThat(verb: "throw at")
                )
            }

            _ = try await engine.item(targetItemID)
            guard await engine.playerCanReach(targetItemID) else {
                throw ActionResponse.itemNotAccessible(targetItemID)
            }
        }
    /// Processes the "THROW" command.
    ///
    /// Handles different throwing scenarios:
    /// - Throwing at specific targets
    /// - General throwing (drops item in current location)
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` with appropriate throwing message and state changes.
        guard let directObjectRef = command.directObject else {
            throw ActionResponse.internalEngineError(
                "ThrowActionHandler: directObject was nil in process."
            )
        }

        // Handle self reference
        if case .player = directObjectRef {
            return ActionResult(
                engine.messenger.cannotVerbYourself(verb: "throw")
            )
        }

        guard case .item(let itemToThrowID) = directObjectRef else {
            throw ActionResponse.internalEngineError(
                "ThrowActionHandler: directObject was not an item in process."
            )
        }

        let itemToThrow = try await engine.item(itemToThrowID)
        let currentLocationID = await engine.playerLocationID

        // Handle specific target throwing
        if let indirectObjectRef = command.indirectObject,
            case .item(let targetItemID) = indirectObjectRef
        {
            let targetItem = try await engine.item(targetItemID)

            let message =
                if targetItem.hasFlag(.isCharacter) {
                    engine.messenger.throwAtCharacter(
                        item: itemToThrow.withDefiniteArticle,
                        character: targetItem.withDefiniteArticle
                    )
                } else {
                    engine.messenger.throwAtObject(
                        item: itemToThrow.withDefiniteArticle,
                        target: targetItem.withDefiniteArticle
                    )
                }

            return ActionResult(
                message,
                await engine.setFlag(.isTouched, on: itemToThrow),
                await engine.updatePronouns(to: itemToThrow),
                await engine.move(itemToThrow, to: .location(currentLocationID)),
                await engine.setFlag(.isTouched, on: targetItem)
            )
        } else {
            // General throwing - no specific target
            return ActionResult(
                engine.messenger.throwGeneral(
                    item: itemToThrow.withDefiniteArticle
                ),
                await engine.setFlag(.isTouched, on: itemToThrow),
                await engine.updatePronouns(to: itemToThrow),
                await engine.move(itemToThrow, to: .location(currentLocationID))
            )
        }
    }

    /// Performs any post-processing after the throw action completes.
    ///
    /// Currently no post-processing is needed for throwing.
    ///
    /// - Parameter context: The action context for the current action.
    public func postProcess(context: ActionContext) async throws {
        // No post-processing needed for throw
    }
}
