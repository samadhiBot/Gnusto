import Foundation

/// Handles the DANCE verb for dancing, boogieing, or expressing joy through movement.
///
/// This is a humorous atmospheric command that provides entertaining responses
/// to player attempts to dance. Based on ZIL tradition, including the classic
/// "Dancing is forbidden" response from Cloak of Darkness.
public struct DanceActionHandler: ActionHandler {
    public init() {}

    public func process(
        context: ActionContext
    ) async throws -> ActionResult {
        let responses = [
            "Dancing is forbidden.", // Classic ZIL response from Cloak of Darkness
            "You dance a little jig. How delightful!",
            "You boogie down with surprising grace.",
            "You perform an interpretive dance. Very artistic.",
            "You dance like nobody's watching (which they aren't).",
            "You cut a rug with style and panache.",
            "You dance the dance of your people.",
            "You waltz around the area with imaginary partners.",
            "You break into spontaneous choreography.",
            "You dance with wild abandon. Bravo!"
        ]

        return ActionResult(responses.randomElement()!)
    }
}
