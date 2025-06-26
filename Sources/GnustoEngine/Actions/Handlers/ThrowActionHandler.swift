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

    public let verbs: [Verb] = [.throw, .hurl, .toss, .chuck]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "THROW" command.
    ///
    /// Handles different throwing scenarios:
    /// - Throwing at specific targets
    /// - General throwing (drops item in current location)
    ///
    /// - Parameter command: The command being processed.
    /// - Parameter engine: The game engine.
    /// - Returns: An `ActionResult` with appropriate throwing message and state changes.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        // Throw requires a direct object (what to throw)
        guard let directObjectRef = command.directObject else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.doWhat(verb: command.verb)
            )
        }

        // Handle self reference
        if case .player = directObjectRef {
            return ActionResult(
                engine.messenger.cannotVerbYourself(verb: "throw")
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

            let targetItem = try await engine.item(targetItemID)

            guard await engine.playerCanReach(targetItemID) else {
                throw ActionResponse.itemNotAccessible(targetItemID)
            }

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

            let currentLocationID = await engine.playerLocationID

            return ActionResult(
                message,
                await engine.setFlag(.isTouched, on: itemToThrow),
                await engine.updatePronouns(to: itemToThrow),
                await engine.move(itemToThrow, to: .location(currentLocationID)),
                await engine.setFlag(.isTouched, on: targetItem)
            )
        } else {
            // General throwing - no specific target
            let currentLocationID = await engine.playerLocationID

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
}
