import Foundation

/// Handles the GIGGLE verb for giggling, chuckling, or expressing amusement.
///
/// This is a humorous atmospheric command that provides entertaining responses
/// to player attempts to giggle or chuckle. Based on ZIL tradition.
public struct GiggleActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let verbID: VerbID = .giggle

    public let syntax: [SyntaxRule] = [
        SyntaxRule(.verb)
    ]

    public let synonyms: [String] = ["chuckle"]

    public let requiresLight: Bool = false

    // MARK: - Action Processing Methods

    public init() {}

    public func process(
        context: ActionContext
    ) async throws -> ActionResult {
        ActionResult(
            context.message.giggleResponse()
        )
    }
}
