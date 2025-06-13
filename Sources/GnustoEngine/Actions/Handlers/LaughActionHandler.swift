import Foundation

/// Handles the LAUGH verb for laughing, guffawing, or expressing mirth.
///
/// This is a humorous atmospheric command that provides entertaining responses
/// to player attempts to laugh. Based on ZIL tradition.
public struct LaughActionHandler: ActionHandler {
    public init() {}

    public func process(
        context: ActionContext
    ) async throws -> ActionResult {
        let responses = [
            "You laugh heartily.",
            "You guffaw with abandon.",
            "You chortle with glee.",
            "You cackle like a witch.",
            "You laugh until your sides hurt.",
            "You burst into uncontrollable laughter.",
            "You laugh at the cosmic joke of it all.",
            "You roar with laughter.",
            "You laugh maniacally. How disturbing!",
            "You laugh so hard you nearly fall over."
        ]

        return ActionResult(
            try await context.engine.randomElement(in: responses)
        )
    }
}
