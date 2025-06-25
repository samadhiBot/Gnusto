import Foundation

/// Handles the LAUGH verb for laughing, guffawing, or expressing mirth.
///
/// This is a humorous atmospheric command that provides entertaining responses
/// to player attempts to laugh. Based on ZIL tradition.
public struct LaughActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb),
        .match(.verb, .at, .directObject),
    ]

    public let verbs: [VerbID] = [.laugh, .chuckle, .giggle, .snicker, .chortle]

    public let requiresLight: Bool = false

    // MARK: - Action Processing Methods

    public init() {}

    public func process(
        context: ActionContext
    ) async throws -> ActionResult {
        ActionResult(
            engine.messenger.laughResponse()
        )
    }
}
