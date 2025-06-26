import Foundation

/// Handles movement commands (e.g., "GO NORTH", "NORTH", "N"), allowing the player to navigate
/// between locations in the game world.
public struct GoActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .direction)
    ]

    public let verbs: [Verb] = [
        .go, .walk, .run, .proceed, .stroll, .hike, .head, .move, .travel,
    ]

    public let requiresLight: Bool = false

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "GO" command.
    ///
    /// This action validates prerequisites and handles moving the player between locations.
    /// Checks for valid direction, exit availability, and door conditions.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        // Identify Direction
        guard let direction = command.direction else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.goWhere()
            )
        }

        // Get Current Location data
        let currentLocationID = await engine.playerLocationID
        let currentLocation = try await engine.location(currentLocationID)

        // Find Exit
        guard let exit = currentLocation.exits[direction] else {
            throw ActionResponse.invalidDirection  // Standard message: "🤡 You can't go that way."
        }

        // Check Exit Conditions

        // Check if exit is permanently blocked (no destination)
        guard let destinationID = exit.destinationID else {
            let message = exit.blockedMessage ?? "You can't go that way."
            throw ActionResponse.directionIsBlocked(message)
        }

        // Check for static blocked message
        if let staticBlockedMessage = exit.blockedMessage {
            throw ActionResponse.directionIsBlocked(staticBlockedMessage)
        }

        // Check door conditions if exit has a doorID
        if let doorID = exit.doorID {
            let door = try await engine.item(doorID)

            // Only apply door validation if this is actually a door
            // Non-door objects (like stairs, ladders, ropes) used via ClimbActionHandler don't need to be "open"
            if door.hasFlag(.isDoor) {
                // Check if the door is locked
                if door.hasFlag(.isLocked) {
                    throw ActionResponse.directionIsBlocked(
                        engine.messenger.doorIsLocked(
                            door: door.withDefiniteArticle.capitalizedFirst)
                    )
                }

                // Check if the door is open
                guard door.hasFlag(.isOpen) else {
                    throw ActionResponse.directionIsBlocked(
                        engine.messenger.doorIsClosed(
                            door: door.withDefiniteArticle.capitalizedFirst)
                    )
                }
            }
        }

        // Movement itself doesn't usually print a message; the new location description suffices.
        // The engine's run loop will trigger describeCurrentLocation after state changes.
        return ActionResult(
            await engine.movePlayer(to: destinationID)
        )
    }
}
