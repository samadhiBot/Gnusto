import Foundation

/// Handles the "ENTER" command and its synonyms (e.g., "GO IN", "GET IN").
/// Implements entering objects and locations following ZIL patterns.
public struct EnterActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let verbID: VerbID = .enter

    public let syntax: [SyntaxRule] = [
        SyntaxRule(.verb, .directObject)
    ]

    public let synonyms: [String] = []

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
    public func validate(context: ActionContext) async throws {
        // ENTER with no object - look for default enterable in location
        guard let directObjectRef = context.command.directObject else {
            // Look for enterable objects in current location
            let currentLocation = try await context.engine.playerLocation()
            let enterableItems = await context.engine.items(in: .location(currentLocation.id))
                .filter { $0.hasFlag(.isEnterable) }

            if enterableItems.isEmpty {
                throw ActionResponse.prerequisiteNotMet(
                    context.message.nothingHereToEnter()
                )
            }
            return  // Will handle selection in process
        }

        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet(
                context.message.cannotDoThat(verb: "enter")
            )
        }

        // Check if target exists and is reachable
        let targetItem = try await context.engine.item(targetItemID)
        guard await context.engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }

        // Check if item is enterable
        guard targetItem.hasFlag(.isEnterable) else {
            throw ActionResponse.prerequisiteNotMet(
                context.message.cannotEnter(item: targetItem.withDefiniteArticle)
            )
        }
    }

    /// Processes the "ENTER" command.
    ///
    /// Handles entering objects or finding default enterable objects.
    /// Can trigger movement if the enterable object enables traversal.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` with appropriate enter message and state changes.
    public func process(context: ActionContext) async throws -> ActionResult {
        let currentLocation = try await context.engine.playerLocation()

        // Handle ENTER with no object - find default enterable
        guard let directObjectRef = context.command.directObject else {
            let enterableItems = await context.engine.items(in: .location(currentLocation.id))
                .filter { $0.hasFlag(.isEnterable) }

            guard let firstEnterable = enterableItems.first else {
                throw ActionResponse.prerequisiteNotMet(
                    context.message.nothingHereToEnter()
                )
            }

            return ActionResult(
                message: "You enter the \(firstEnterable.name).",
                changes: [
                    await context.engine.setFlag(.isTouched, on: firstEnterable),
                    await context.engine.updatePronouns(to: firstEnterable),
                ]
            )
        }

        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.internalEngineError(
                "EnterActionHandler: directObject was not an item in process.")
        }

        let targetItem = try await context.engine.item(targetItemID)

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
                    engine: context.engine
                )

                try await goHandler.validate(context: goContext)
                let goResult = try await goHandler.process(context: goContext)

                // Combine state changes from enter (touch/pronouns) with go result
                return ActionResult(
                    message: goResult.message,
                    changes: [
                        await context.engine.setFlag(.isTouched, on: targetItem),
                        await context.engine.updatePronouns(to: targetItem),
                    ] + goResult.changes
                )
            }
        }

        // No movement enabled - basic enter behavior
        return ActionResult(
            message: "You enter the \(targetItem.name).",
            changes: [
                await context.engine.setFlag(.isTouched, on: targetItem),
                await context.engine.updatePronouns(to: targetItem),
            ]
        )
    }

    /// Performs any post-processing after the enter action completes.
    ///
    /// Currently no post-processing is needed for basic enter behavior.
    ///
    /// - Parameter context: The action context for the current action.
    public func postProcess(context: ActionContext) async throws {
        // No post-processing needed for enter
    }
}
