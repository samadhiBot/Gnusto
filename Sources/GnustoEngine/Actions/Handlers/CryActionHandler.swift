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
            "You sob dramatically, and feel a little better.",
            "You cry a bit. There, there now.",
            "You bawl your eyes out, which is somewhat cathartic.",
            "You weep with the passion of a thousand sorrows.",
            "You cry like a baby. How embarrassing.",
            "You shed crocodile tears. Very convincing.",
            "You weep bitter tears.",
            "You break down and cry. After a bit the world seems a little brighter."
        ]

        return ActionResult(
            try await context.engine.randomElement(in: responses)
        )
    }
}
