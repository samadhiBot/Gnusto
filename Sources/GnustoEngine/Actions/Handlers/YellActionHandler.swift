import Foundation

/// Handles the YELL verb for yelling, shouting, or making loud vocalizations.
///
/// This is a humorous atmospheric command that provides entertaining responses
/// to player attempts to yell or shout. Based on ZIL tradition.
public struct YellActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let verbID: VerbID = .yell

    public let syntax: [SyntaxRule] = [
        .match(.verb),
        .match(.verb, .at, .directObject),
    ]

    public let synonyms: [String] = ["shout", "scream", "shriek", "holler"]

    public let requiresLight: Bool = false

    // MARK: - Action Processing Methods

    public init() {}

    public func process(
        context: ActionContext
    ) async throws -> ActionResult {
        ActionResult(
            context.message.yellResponse()
        )
    }
}
