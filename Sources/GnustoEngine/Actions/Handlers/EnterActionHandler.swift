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

    /// Processes the "ENTER" command.
    ///
    /// This action validates prerequisites and handles entering objects or finding default
    /// enterable objects. Can trigger movement if the enterable object enables traversal.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        let currentLocation = try await engine.playerLocation()

        // Handle ENTER with no object - look for default enterable in location
        guard let directObjectRef = command.directObject else {
            let enterableItems = await engine.items(in: .location(currentLocation.id))
                .filter { $0.hasFlag(.isEnterable) }

            if enterableItems.isEmpty {
                throw ActionResponse.prerequisiteNotMet(
                    engine.messenger.nothingHereToEnter()
                )
            } else if enterableItems.count == 1 {
                // Auto-select the only enterable item
                let targetItem = enterableItems[0]
                return try await processEnter(
                    targetItem: targetItem,
                    currentLocation: currentLocation,
                    engine: engine
                )
            } else {
                // Multiple enterable items - ask for clarification
                throw ActionResponse.prerequisiteNotMet(
                    "🤡 engine.messenger.whichToEnter"
//                    engine.messenger.whichToEnter(
//                        items: enterableItems.listWithDefiniteArticles
//                    )
                )
            }
        }

        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.cannotDoThat(verb: "enter")
            )
        }

        // Check if target exists and is accessible
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

        return try await processEnter(
            targetItem: targetItem,
            currentLocation: currentLocation,
            engine: engine
        )
    }

    // MARK: - Helper Methods

    /// Processes entering a specific item, handling both movement and containment.
    ///
    /// - Parameters:
    ///   - targetItem: The item to enter.
    ///   - currentLocation: The player's current location.
    ///   - engine: The game engine instance.
    /// - Returns: An ActionResult with appropriate messaging and state changes.
    private func processEnter(
        targetItem: Item,
        currentLocation: Location,
        engine: GameEngine
    ) async throws -> ActionResult {
        // Check if this object enables traversal (like GO command)
        for (direction, exit) in currentLocation.exits {
            if exit.doorID == targetItem.id {
                // This object enables movement - delegate to GO command
                let goCommand = Command(
                    verb: .go,
                    direction: direction,
                    rawInput: "go \(direction.rawValue)"
                )

                let goHandler = GoActionHandler()
                let goResult = try await goHandler.process(command: goCommand, engine: engine)

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

        // No movement enabled - check if item is a container the player can enter
        if targetItem.hasFlag(.isContainer) && targetItem.hasFlag(.isOpen) {
            // Enter the container (move player inside)
            return ActionResult(
                "🤡 engine.messenger.enterContainer(container: targetItem.withDefiniteArticle)",
                await engine.setFlag(.isTouched, on: targetItem),
                await engine.updatePronouns(to: targetItem),
                await engine.movePlayer(to: .item(targetItem.id))
            )
        } else if targetItem.hasFlag(.isContainer) && !targetItem.hasFlag(.isOpen) {
            // Container is closed
            throw ActionResponse.containerIsClosed(targetItem.id)
        } else {
            // Default enter behavior - just provide a message
            return ActionResult(
                "🤡 engine.messenger.enterGeneric(item: targetItem.withDefiniteArticle)",
                await engine.setFlag(.isTouched, on: targetItem),
                await engine.updatePronouns(to: targetItem)
            )
        }
    }
}
