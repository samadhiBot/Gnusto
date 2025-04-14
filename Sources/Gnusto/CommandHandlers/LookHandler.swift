import Foundation

/// Handles the "look" command (looking around the current location).
struct LookHandler {
    /// The main handler function for the "look" verb.
    ///
    /// This handler specifically deals with looking around the current room.
    /// It returns `nil` if the command has a direct object (e.g., "look at ball"),
    /// deferring that to an `ExamineHandler`.
    ///
    /// - Parameters:
    ///   - context: The command context containing user input and world state.
    /// - Returns: An array of effects describing the room, or nil if not applicable.
    static func handle(context: CommandContext) -> [Effect]? {
        let command = context.userInput
        let world = context.world

        // LookHandler only handles "look" (no direct object)
        guard command.directObject == nil else {
            // "look at <obj>" should be handled by ExamineHandler
            return nil
        }

        guard let playerLocation = world.playerLocation else {
            return [.showText("You can't see anything from nowhere.")]
        }

        // Check darkness
        if !world.isIlluminated(playerLocation.id) {
            let darkDesc = playerLocation.find(RoomComponent.self)?.darkDescription
            return [.showText(darkDesc ?? "It is pitch black. You are likely to be eaten by a grue.")]
        }

        // --- Describe Illuminated Room ---
        guard let descComponent = playerLocation.find(DescriptionComponent.self) else {
             // This should generally not happen for a valid room location
            return [.showText("You are in an indescribable location.")]
        }

        var effects: [Effect] = []

        // Room Name/Title
        // TODO: Potentially use brief description flag later
        effects.append(.showText(descComponent.name.uppercased()))

        // Room Description
        effects.append(.showText(descComponent.description))

        // Show visible objects (excluding player and scenery)
        let visibleObjects = world.find(in: playerLocation.id) // Use world.find(in:)
            .filter { obj in
                let isPlayer = obj.id == world.player.id
                // Explicitly use Flag.scenery (now defined)
                let isScenery = obj.find(ObjectComponent.self)?.flags.contains(Flag.scenery) ?? false
                return !isPlayer && !isScenery
            }

        if !visibleObjects.isEmpty {
            let names = visibleObjects
                .compactMap { $0.find(DescriptionComponent.self)?.name } // Get names
                .sorted() // Sort alphabetically
            if !names.isEmpty {
                 effects.append(.showText("You can see: \(names.joined(separator: ", "))."))
            }
        }

        // Show exits (Using RoomComponent based on original code)
        if let roomComponent = playerLocation.find(RoomComponent.self),
           !roomComponent.exits.isEmpty
        {
             // Get explicitly defined exits for the room
             let exitNames = roomComponent.exits.keys
                                      .map { $0.rawValue } // Get string names
                                      .sorted() // Sort the strings

            // Note: The original code checked exit.destination. This implementation
            // simply lists defined exits. Dynamic availability checks could be added.
            if !exitNames.isEmpty {
                effects.append(.showText("Exits: \(exitNames.joined(separator: ", "))"))
            }
        }

        // TODO: Add status line update effect?
        // effects.append(.updateStatusLine(...))

        return effects // Return the effects gathered so far for the look description
    }
}
