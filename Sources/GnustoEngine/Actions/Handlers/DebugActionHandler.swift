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

    public let synonyms: [Verb] = [.debug]

    public let requiresLight: Bool = false

    public let consumesTurn: Bool = false

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "DEBUG" command.
    ///
    /// Retrieves the specified entity (item, location, or player) from the `GameState`
    /// and uses `customDump` to generate a string representation of its properties and values.
    ///
    /// - Parameter command: The command being processed.
    /// - Parameter engine: The game context.engine.
    /// - Returns: An `ActionResult` containing the detailed dump of the target entity.
    public func process(context: ActionContext) async throws -> ActionResult {
        guard let directObjectRef = context.command.directObject else {
            throw ActionResponse.feedback(
                context.msg.debugRequiresObject()
            )
        }

        var target = ""

        switch directObjectRef {
        case .player:
            await customDump(context.engine.gameState.player, to: &target)

        case .item(let proxy):
            customDump(proxy.item, to: &target)

        case .location(let proxy):
            customDump(proxy.location, to: &target)

        case .universal(let universal):
            customDump(universal, to: &target)
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
