import Foundation

/// Handles the GIGGLE verb for giggling, chuckling, or expressing amusement.
///
/// This is a humorous atmospheric command that provides entertaining responses
/// to player attempts to giggle or chuckle. Based on ZIL tradition.
public struct GiggleActionHandler: ActionHandler {
    public init() {}

    public func process(
        context: ActionContext
    ) async throws -> ActionResult {
        let responses = [
            "You giggle softly to yourself.",
            "You chuckle with amusement.",
            "You snicker quietly. How mischievous!",
            "You titter like a schoolchild.",
            "You giggle uncontrollably. How embarrassing!",
            "You chuckle at some private joke.",
            "You giggle with glee.",
            "You snicker at the absurdity of it all.",
            "You chortle with delight.",
            "You giggle like a maniac. Very therapeutic."
        ]

        return ActionResult(
            try await context.engine.randomElement(in: responses)
        )
    }
}
