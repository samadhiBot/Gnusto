import Foundation

/// Handles the "BRIEF" command for setting brief description mode.
/// Controls verbosity of location descriptions following ZIL traditions.
public struct BriefActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb)
    ]

    public let verbs: [VerbID] = [.brief]

    public let requiresLight: Bool = false

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "BRIEF" command.
    ///
    /// Sets the game to brief mode, where location descriptions are only shown
    /// when entering a location for the first time or when explicitly looking.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        return ActionResult(
            """
            Brief mode is now on. Location descriptions will be
            shown only when you first enter a location.
            """,
            await engine.setGlobal(.isBriefMode, to: true),
            await engine.clearGlobal(.isVerboseMode)
        )
    }
}
