import Foundation

/// Handles the "HELP" command for displaying game help information.
/// Provides basic interactive fiction command guidance following ZIL traditions.
public struct HelpActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb)
    ]

    public let verbs: [Verb] = [.help]

    public let requiresLight: Bool = false

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "HELP" command.
    ///
    /// Displays basic help information about common interactive fiction commands.
    /// Games can override this with custom help via ItemEventHandlers or custom handlers.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        let helpText = """
            This is an interactive fiction game. You control the story by typing commands.

            Common commands:
            • LOOK or L - Look around your current location
            • EXAMINE <object> or X <object> - Look at something closely
            • TAKE <object> or GET <object> - Pick up an item
            • DROP <object> - Put down an item you're carrying
            • INVENTORY or I - See what you're carrying
            • GO <direction> or just <direction> - Move in a direction (N, S, E, W, etc.)
            • OPEN <object> - Open doors, containers, etc.
            • CLOSE <object> - Close doors, containers, etc.
            • PUT <object> IN <container> - Put something in a container
            • PUT <object> ON <surface> - Put something on a surface
            • SAVE - Save your game
            • RESTORE - Restore a saved game
            • QUIT or Q - End the game

            You can use multiple objects with some commands (TAKE ALL, DROP SWORD AND SHIELD).
            Try different things - experimentation is part of the fun!
            """

        return ActionResult(helpText)
    }
}
