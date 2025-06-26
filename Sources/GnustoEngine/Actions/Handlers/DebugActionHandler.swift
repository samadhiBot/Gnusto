import CustomDump
import Foundation

/// Handles the "DEBUG" command, providing a way for game developers to inspect the
/// internal state of game entities during development and testing.
///
/// The DEBUG command requires a direct object (e.g., "DEBUG LANTERN", "DEBUG SELF",
/// "DEBUG WEST_OF_HOUSE"). It outputs a detailed, developer-friendly representation
/// of the specified item, location, or the player object using the `swift-custom-dump` library.
///
/// > Note: This handler is a development tool, and is only available in DEBUG game builds.
public struct DebugActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject)
    ]

    public let verbs: [VerbID] = [.debug]

    public let requiresLight: Bool = false

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "DEBUG" command.
    ///
    /// Retrieves the specified entity (item, location, or player) from the `GameState`
    /// and uses `customDump` to generate a string representation of its properties and values.
    ///
    /// - Parameter command: The command being processed.
    /// - Parameter engine: The game engine.
    /// - Returns: An `ActionResult` containing the detailed dump of the target entity.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        guard let directObjectRef = command.directObject else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.debugRequiresObject()
            )
        }

        var target = ""

        switch directObjectRef {
        case .player:
            await customDump(engine.gameState.player, to: &target)

        case .item(let itemID):
            guard let item = await engine.gameState.items[itemID] else {
                throw ActionResponse.unknownEntity(directObjectRef)
            }
            customDump(item, to: &target)

        case .location(let locationID):
            guard let location = await engine.gameState.locations[locationID] else {
                throw ActionResponse.unknownEntity(directObjectRef)
            }
            customDump(location, to: &target)
        }

        return ActionResult(
            """
            ```
            \(target)
            ```
            """
        )
    }
}
