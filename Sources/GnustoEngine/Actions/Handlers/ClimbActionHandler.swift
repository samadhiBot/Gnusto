import Foundation

/// Handles the "CLIMB" command, allowing the player to climb objects.
///
/// This handler implements ZIL-inspired behavior for climbing. When the player
/// climbs an object, the handler:
/// 1. Checks if the object enables traversal of any exit in the current location
/// 2. If so, uses that exit (e.g., "climb stairs" -> "go up")
/// 3. Otherwise, provides default climbing behavior for climbable objects
///
/// This works with the Exit system's `via:` parameter to create flexible
/// climbing-based movement (stairs, ladders, ropes, etc.).
public struct ClimbActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb),
        .match(.verb, .directObject),
    ]

    public let verbs: [VerbID] = [.climb, .ascend]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    /// Validates the "CLIMB" command.
    ///
    /// This method ensures that:
    /// 1. If a direct object is specified, it exists and is reachable.
    /// 2. The object is present in the current location (for global objects like stairs)
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: Various `ActionResponse` errors if validation fails.
        public func process(
        command: Command,
        engine: GameEngine
    ) async throws -> ActionResult {

        // CLIMB with no object is always valid (will be handled in process)
        guard let directObjectRef = command.directObject else {
            return
        }

        let targetItemID: ItemID
        switch directObjectRef {
        case .item(let itemID):
            targetItemID = itemID
        case .location:
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.cannotDoThat(verb: "climb")
            )
        case .player:
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.cannotVerbYourself(verb: "climb")
            )
        }

        // Check if the target exists
        guard (try? await engine.item(targetItemID)) != nil else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }

        // Check if the target is reachable
        guard await engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }
    /// Processes the "CLIMB" command.
    ///
    /// This method handles various climbing scenarios:
    /// 1. "climb" with no object - asks what to climb
    /// 2. "climb <object>" that enables an exit - traverses that exit
    /// 3. "climb <climbable object>" - default climbing behavior
    /// 4. "climb <non-climbable object>" - error message
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` containing the message and any relevant state changes.
        // Handle CLIMB with no object
        guard let directObjectRef = command.directObject else {
            return ActionResult(
                engine.messenger.doWhat(verb: command.verb)
            )
        }

        guard case .item(let targetItemID) = directObjectRef else {
            let message = engine.messenger.actionHandlerInternalError(
                handler: "ClimbActionHandler",
                details: "directObject was not an item in process"
            )
            throw ActionResponse.internalEngineError(message)
        }

        let targetItem = try await engine.item(targetItemID)
        let currentLocation = try await engine.playerLocation()

        // Check if this object enables traversal of any exit in the current location
        // Sort directions to ensure consistent behavior when multiple exits use the same object
        // Priority: north, northeast, east, southeast, south, southwest, west, northwest, up, down, inside, outside
        let sortedExits = currentLocation.exits.sorted { first, second in
            first.key < second.key
        }

        for (direction, exit) in sortedExits {
            if exit.doorID == targetItemID {
                // This object enables traversal in this direction

                // For global objects like stairs, verify they're actually present
                if targetItem.parent == .nowhere,
                    currentLocation.localGlobals.contains(targetItemID) == false
                {
                    return ActionResult(
                        engine.messenger.youSeeNo(item: targetItem.name)
                    )
                }

                // Execute movement in the appropriate direction
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

                // Combine state changes from climb (touch/pronouns) with go result
                return ActionResult(
                    message: goResult.message,
                    changes: [
                        await engine.setFlag(.isTouched, on: targetItem),
                        await engine.updatePronouns(to: targetItem),
                    ] + goResult.changes
                )
            }
        }

        // No exit uses this object, so handle as regular climbing

        // Check if the item is climbable
        let message =
            if targetItem.hasFlag(.isClimbable) {
                // Default climbable behavior - can be overridden by specific item handlers
                engine.messenger.climbSuccess(item: targetItem.withDefiniteArticle)
            } else {
                // Not climbable
                engine.messenger.climbFailure(item: targetItem.withDefiniteArticle)
            }

        return ActionResult(
            message,
            await engine.setFlag(.isTouched, on: targetItem),
            await engine.updatePronouns(to: targetItem)
        )
    }
}
