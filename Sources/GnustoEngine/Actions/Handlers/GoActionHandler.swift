import Foundation

/// Handles movement commands (e.g., "GO NORTH", "NORTH", "N"), allowing the player to navigate
/// between locations in the game world.
public struct GoActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .direction)
    ]

    public let synonyms: [Verb] = [
        .go, .walk, .run, .proceed, .stroll, .hike, .head, .move, .travel,
    ]

    public let requiresLight: Bool = false

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "GO" command.
    ///
    /// This action validates prerequisites and handles moving the player between locations.
    /// Checks for valid direction, exit availability, and door conditions.
    public func process(context: ActionContext) async throws -> ActionResult {
        // Identify Direction
        guard let direction = context.command.direction else {
            throw ActionResponse.feedback(
                context.msg.goWhere()
            )
        }

        // Get Current Location data
        let currentLocation = await context.player.location

        // Find Exit
        guard
            let exit = await currentLocation.exits
                .first(where: { $0.direction == direction })
        else {
            throw ActionResponse.invalidDirection
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
            let door = await context.item(doorID)

            // Apply door validation based on the item's specific capabilities
            // Check if the door is locked (only applies to lockable items)
            let isLockable = await door.hasFlag(.isLockable)
            let isLocked = await door.hasFlag(.isLocked)

            if isLockable && isLocked {
                throw await ActionResponse.directionIsBlocked(
                    context.msg.doorIsLocked(door.withDefiniteArticle)
                )
            }

            // Check if the door is closed (only applies to openable doors)
            let isOpenable = await door.isOpenable
            let isOpen = await door.isOpen

            if isOpenable && !isOpen {
                throw await ActionResponse.directionIsBlocked(
                    context.msg.doorIsClosed(door.withDefiniteArticle)
                )
            }
        }

        // Movement itself doesn't usually print a message; the new location description suffices.
        // The engine's run loop will trigger describeCurrentLocation after state changes.
        return ActionResult(
            await context.player.move(to: destinationID)
        )
    }
}
