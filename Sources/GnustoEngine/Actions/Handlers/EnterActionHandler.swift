import Foundation

/// Handles the "ENTER" command and its synonyms (e.g., "GO IN", "GET IN").
/// Implements entering objects that serve as doors/passages between locations.
public struct EnterActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.get, .in, .directObject),
        .match(.go, .in, .directObject),
        .match(.go, .through, .directObject),
        .match(.enter, .directObject),
    ]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "ENTER" command.
    ///
    /// This action finds items that serve as doors/passages in the current location's exits,
    /// then delegates to the GO command to handle the actual movement.
    public func process(context: ActionContext) async throws -> ActionResult {
        guard let target = try await context.itemDirectObject() else {
            // Handle ENTER with no object - look for enterable doors in location
            let enterableDoors = try await findEnterableDoors(in: context)
            if enterableDoors.count == 1 {
                // Auto-select the only enterable door
                let (doorItem, direction) = enterableDoors[0]
                return try await processEnterDoor(doorItem, to: direction)
            } else {
                // Zero or Multiple enterable doors - ask for clarification
                throw ActionResponse.feedback(
                    context.msg.whichEntrance()
                )
            }
        }

        let currentLocation = try await context.player.location

        // Find if this item serves as a door for any exit from current location
        guard
            let direction = try await findExitDirection(for: target, in: currentLocation)
        else {
            throw await ActionResponse.feedback(
                context.msg.cannotDo(context.command, item: target.withDefiniteArticle)
            )
        }

        return try await processEnterDoor(target, to: direction)
    }

    // MARK: - Helper Methods

    /// Finds all items in the current location that serve as doors for exits.
    ///
    /// - Parameters:
    ///   - location: The current location to search.
    ///   - engine: The game engine instance.
    /// - Returns: Array of (doorItem, direction) tuples for enterable doors.
    private func findEnterableDoors(
        in context: ActionContext
    ) async throws -> [(doorItem: ItemProxy, direction: Direction)] {
        var enterableDoors = [(doorItem: ItemProxy, direction: Direction)]()
        let location = try await context.player.location

        for exit in try await location.exits {
            // Skip exits without doorIDs (they're not associated with objects)
            guard let doorID = exit.doorID else { continue }

            let door = try await context.engine.item(doorID)

            if await door.playerCanReach {
                enterableDoors.append(
                    (doorItem: door, direction: exit.direction)
                )
            }
        }

        return enterableDoors
    }

    /// Finds the exit direction for a given item ID in the current location.
    ///
    /// - Parameters:
    ///   - itemID: The ID of the item to check.
    ///   - location: The current location.
    /// - Returns: The direction of the exit that uses this item as a door, or nil if none found.
    private func findExitDirection(
        for item: ItemProxy,
        in location: LocationProxy
    ) async throws -> Direction? {
        guard let exit = try await location.exits.first(
            where: { $0.doorID == item.id }
        ) else {
            return nil
        }
        return exit.direction
    }

    /// Processes entering through a specific door, delegating to the GO context.command.
    ///
    /// - Parameters:
    ///   - doorItem: The door item being entered.
    ///   - direction: The direction of movement.
    ///   - engine: The game engine instance.
    /// - Returns: An ActionResult combining enter effects with movement.
    private func processEnterDoor(
        _ doorItem: ItemProxy,
        to direction: Direction
    ) async throws -> ActionResult {
        // Delegate to GO command for the actual movement
        let goCommand = Command(verb: .go, direction: direction)
        let goResult = try await GoActionHandler().process(
            context: ActionContext(goCommand, doorItem.engine)
        )

        // Combine door interaction effects with movement result
        return ActionResult(
            message: goResult.message,
            changes: [try await doorItem.setFlag(.isTouched)] + goResult.changes
        )
    }
}
