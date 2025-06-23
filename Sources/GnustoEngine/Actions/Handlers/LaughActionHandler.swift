import Foundation

/// Handles the LAUGH verb for laughing, guffawing, or expressing mirth.
///
/// This is a humorous atmospheric command that provides entertaining responses
/// to player attempts to laugh. Based on ZIL tradition.
public struct LaughActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let verbID: VerbID = .laugh

    public let syntax: [SyntaxRule] = [
        SyntaxRule(.verb),
        SyntaxRule(.verb, .at, .directObject),
    ]

    public let synonyms: [String] = []

    public let requiresLight: Bool = false

    // MARK: - Action Processing Methods

    public init() {}

    public func process(
        context: ActionContext
    ) async throws -> ActionResult {
        ActionResult(
            context.message.laughResponse()
        )
    }
}
