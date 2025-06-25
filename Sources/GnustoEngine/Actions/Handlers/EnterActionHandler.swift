import Foundation

/// Handles the "ENTER" command and its synonyms (e.g., "GO IN", "GET IN").
/// Implements entering objects and locations following ZIL patterns.
public struct EnterActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject)
    ]

    public let verbs: [VerbID] = [.enter]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Validates the "ENTER" command.
    ///
    /// This method ensures that:
    /// 1. If a direct object is specified, it exists and is reachable.
    /// 2. If no object is specified, tries to find a suitable enterable object.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: Various `ActionResponse` errors if validation fails.
        public func process(
        command: Command,
        engine: GameEngine
    ) async throws -> ActionResult {

        // ENTER with no object - look for default enterable in location
        guard let directObjectRef = command.directObject else {
            // Look for enterable objects in current location
            let currentLocation = try await engine.playerLocation()
            let enterableItems = await engine.items(in: .location(currentLocation.id))
                .filter { $0.hasFlag(.isEnterable) }

            if enterableItems.isEmpty {
                throw ActionResponse.prerequisiteNotMet(
                    engine.messenger.nothingHereToEnter()
                )
            }
            return  // Will handle selection in process
        }

        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.cannotDoThat(verb: "enter")
            )
        }

        // Check if target exists and is reachable
        let targetItem = try await engine.item(targetItemID)
        guard await engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }

        // Check if item is enterable
        guard targetItem.hasFlag(.isEnterable) else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.cannotDoThat(
                    verb: .enter,
                    item: targetItem.withDefiniteArticle
                )
            )
        }
    /// Processes the "ENTER" command.
    ///
    /// Handles entering objects or finding default enterable objects.
    /// Can trigger movement if the enterable object enables traversal.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` with appropriate enter message and state changes.
        let currentLocation = try await engine.playerLocation()

        // Handle ENTER with no object - find default enterable
        guard let directObjectRef = command.directObject else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.doWhat(verb: .enter)
            )
        }

        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.internalEngineError(
                "EnterActionHandler: directObject was not an item in process."
            )
        }

        let targetItem = try await engine.item(targetItemID)

        // Check if this object enables traversal (like GO command)
        for (direction, exit) in currentLocation.exits {
            if exit.doorID == targetItemID {
                // This object enables movement - delegate to GO command
                let goCommand = Command(
                    verb: .go,
                    direction: direction,
                    rawInput: "go \(direction.rawValue)"
                )

                let goHandler = GoActionHandler()
                let goContext = ActionContext(
                    command: goCommand,
                    engine: engine
                )

                try await goHandler.validate(context: goContext)
                let goResult = try await goHandler.process(context: goContext)

                // Combine state changes from enter (touch/pronouns) with go result
                return ActionResult(
                    message: goResult.message,
                    changes: [
                        await engine.setFlag(.isTouched, on: targetItem),
                        await engine.updatePronouns(to: targetItem),
                    ] + goResult.changes
                )
            }
        }

        // No movement enabled - basic enter behavior
        throw ActionResponse.prerequisiteNotMet(
            engine.messenger.doWhat(verb: .enter)
        )
    }
}
