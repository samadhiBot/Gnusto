import Foundation

/// Handles the SING verb for singing, humming, or making musical sounds.
///
/// This is a humorous atmospheric command that provides entertaining responses
/// to player attempts to sing or make music. Based on ZIL tradition.
public struct SingActionHandler: ActionHandler {
    public init() {}

    public func process(
        context: ActionContext
    ) async throws -> ActionResult {
        let responses = [
            "You sing a little ditty. How delightful!",
            "You hum a tune under your breath.",
            "You warble melodiously. Very soothing.",
            "You croon like a nightingale.",
            "You sing off-key. Perhaps stick to adventuring.",
            "You belt out a rousing chorus. Bravo!",
            "You hum the theme from an old adventure game.",
            "You sing a song of your people.",
            "You vocalize with surprising talent.",
            "You sing so beautifully that birds gather to listen."
        ]

        return ActionResult(responses.randomElement()!)
    }
}
