import Foundation

/// Handles the SCREAM verb for screaming, shrieking, or expressing alarm.
///
/// This is a humorous atmospheric command that provides entertaining responses
/// to player attempts to scream or shriek. Based on ZIL tradition.
public struct ScreamActionHandler: ActionHandler {
    public init() {}

    public func process(
        context: ActionContext
    ) async throws -> ActionResult {
        let responses = [
            "You scream at the top of your lungs. Very therapeutic!",
            "You shriek like a banshee.",
            "You let out a blood-curdling scream.",
            "You screech with primal fury.",
            "You howl like a wounded animal.",
            "You scream until your voice is hoarse.",
            "You emit a piercing shriek that echoes through the area.",
            "You scream with the passion of a thousand frustrated souls.",
            "You let loose a scream that would wake the dead.",
            "You scream so loudly that birds flee from nearby trees."
        ]

        return ActionResult(
            try await context.engine.randomElement(in: responses)
        )
    }
}
