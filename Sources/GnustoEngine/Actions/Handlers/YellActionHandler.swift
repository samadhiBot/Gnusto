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
            "You yell at the top of your lungs. Very cathartic!",
            "You shout loudly. Your voice echoes impressively.",
            "You holler with gusto. How invigorating!",
            "You bellow like a bull. Quite intimidating.",
            "You yell so loudly that your ears ring.",
            "You shout with the passion of a thousand warriors.",
            "You let out a mighty roar that shakes the very foundations.",
            "You yell until you're hoarse. Worth it.",
            "You holler like a town crier announcing important news.",
            "You shout so loudly that distant mountains echo back."
        ]

        return ActionResult(
            try await context.engine.randomElement(in: responses)
        )
    }
}
