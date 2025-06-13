import Foundation

/// Handles the CRY verb for weeping, sobbing, or expressing sadness.
///
/// This is a humorous atmospheric command that provides entertaining responses
/// to player attempts to cry or weep. Based on ZIL tradition.
public struct CryActionHandler: ActionHandler {
    public init() {}

    public func process(
        context: ActionContext
    ) async throws -> ActionResult {
        let responses = [
            "You shed a tear for the futility of it all.",
            "You weep quietly to yourself.",
            "You sob dramatically. You feel a little better.",
            "You cry a bit. There, there.",
            "You bawl your eyes out. Very cathartic.",
            "You weep with the passion of a thousand sorrows.",
            "You cry like a baby. How embarrassing.",
            "You shed crocodile tears. Very convincing.",
            "You weep bitter tears of frustration.",
            "You cry softly. The world seems a little brighter now."
        ]

        return ActionResult(
            try await context.engine.randomElement(in: responses)
        )
    }
}
