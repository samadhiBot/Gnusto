import Foundation

/// Handles the YELL verb for yelling, shouting, or making loud vocalizations.
///
/// This is a humorous atmospheric command that provides entertaining responses
/// to player attempts to yell or shout. Based on ZIL tradition.
public struct YellActionHandler: ActionHandler {
    public init() {}

    public func process(
        context: ActionContext
    ) async throws -> ActionResult {
        let responses = [
            "You bellow magnificently as the universe checks its watch.",
            "You bellow with the wild abandon of one who's given up on making sense.",
            "You bellow importantly, although the importance fails to materialize.",
            "You holler with misplaced confidence.",
            "You holler into the void. While the void doesn't reply, it does raise an eyebrow.",
            "You shout with gusto. The world remains studiously unimpressed.",
            "You shout with purpose, although the _exact_ purpose is unclear.",
            "You shout with the determination of one who's definitely onto something, probably.",
            "You yell as if the universe owes you money.",
            "You yell enthusiastically while reality politely ignores you",
            "You yell with conviction about nothing at all.",
        ]

        return ActionResult(
            try await context.engine.randomElement(in: responses)
        )
    }
}
