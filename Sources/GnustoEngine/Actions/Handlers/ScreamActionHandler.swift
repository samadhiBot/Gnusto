import Foundation

/// Handles the SCREAM verb for screaming, shrieking, or expressing alarm.
///
/// This is a humorous atmospheric command that provides entertaining responses
/// to player attempts to scream or shriek. Based on ZIL tradition.
public struct ScreamActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let verbID: VerbID = .scream

    public let syntax: [SyntaxRule] = [
        SyntaxRule(.verb)
    ]

    public let synonyms: [String] = ["shriek"]

    public let requiresLight: Bool = false

    // MARK: - Action Processing Methods

    public init() {}

    public func process(
        context: ActionContext
    ) async throws -> ActionResult {
        ActionResult(
            context.message.screamResponse()
        )
    }
}
