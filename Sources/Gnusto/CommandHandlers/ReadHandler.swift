import Foundation

/// Handles the "read <object>" command.
struct ReadHandler {

    /// Processes the read command.
    ///
    /// - Parameters:
    ///   - command: The user input command, specifying the direct object to read.
    ///   - world: The game world state.
    /// - Returns: An array of effects describing the outcome.
    static func handle(command: UserInput, world: World) -> [Effect]? {
        guard let targetIDString = command.directObject, !targetIDString.isEmpty else {
            return [.showText("What do you want to read?")]
        }

        let targetID = Object.ID(targetIDString)
        guard let targetObject = world.find(targetID) else {
            return [.showText("You don't see '\(targetIDString)' here.")]
        }

        world.mention(targetID)

        // Check if the object is in the player's inventory or the current room
        guard targetObject.isAccessible(to: world.player.id, in: world) else {
            return [.showText("You can't reach \(targetObject.theName) to read it.")]
        }

        // Check for a ReadableComponent
        if let readable = targetObject.find(ReadableComponent.self) {
            return handleReadable(targetObject, component: readable, world: world)
        }

        // Check ObjectComponent for a .readable flag as a fallback?
        // Or just rely on the component.
        if targetObject.find(ObjectComponent.self)?.flags.contains(.readable) ?? false {
             return [.showText("There's nothing written on \(targetObject.theName).")]
        }

        // Default: Cannot be read
        return [.showText("You can't read \(targetObject.theName).")]
    }

    /// Handles reading an object with a ReadableComponent.
    private static func handleReadable(_ object: Object, component: ReadableComponent, world: World) -> [Effect]? {
        if component.text.isEmpty {
            return [.showText("There's nothing written on \(object.theName).")]
        }
        // TODO: Add check for darkness? Reading requires light.
        if let location = world.location(of: world.player.id),
           !world.isIlluminated(location.id)
        {
             return [.showText("It's too dark to read!")]
        }

        // Mark as read if applicable
        if component.markAsReadOnRead {
            world.modify(id: object.id) { object in
                object.modify(ReadableComponent.self) {
                    $0.hasBeenRead = true
                }
            }
        }

        return [.showText(component.text)]
    }
}

// Requires: World, Effect, Object, Object.ID, UserInput, ReadableComponent, ObjectComponent, Flag (.readable)
// Requires: Object extension for .theName, .isAccessible(to:in:)
// Requires: World extension for .location(of:), .isIlluminated(_:)
// Assumes ReadableComponent has `text: String`, `hasBeenRead: Bool`, `markAsReadOnRead: Bool`
