import Foundation

/// Handles the "VERBOSE" command for setting verbose description mode.
/// Controls verbosity of location descriptions following ZIL traditions.
public struct VerboseActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb)
    ]

    public let verbs: [VerbID] = [.verbose]

    public let requiresLight: Bool = false

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "VERBOSE" command.
    ///
    /// Sets the game to verbose mode, where full location descriptions are shown
    /// every time the player enters a location.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        return ActionResult(
            engine.messenger.maximumVerbosity(),
            await engine.setGlobal(.isVerboseMode, to: true),
            await engine.clearGlobal(.isBriefMode)
        )
    }
}
